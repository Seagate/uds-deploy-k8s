#!/bin/bash

HTTPS="https://"
URL_END="uds/v1/task"

NAMESPACE=""
VOLUME=""
SRCURI=""
DSTURI=""
OPERATION=""
MODE="ENTERPRISE_PERFORMANCE"
FILTER="*"

while [[ $# -gt 0 ]]
do
    case $1 in
        -h|--help)
            printf "Post a task request to a Pilot Link Data Service\n"
            printf "\n"
            printf "Examples:\n"
            printf "  # Post an INGEST task to a Pilot Link Data Service\n"
            printf "  task_POST_pilot_link.sh -n namespace -p pilot-link-ds1 -o INGEST -s 3847d4b20006 -d b3bdbb197efd\n"
            printf "\n"
            printf "  # Post an EXPORT task to a Pilot Link Data Service\n"
            printf "  task_POST_pilot_link.sh -n namespace -p pilot-link-ds1 -o EXPORT -s b3bdbb197efd -d 0754537040c8 -f f05b173050084140aa40ed4875fb7e57\n"
            printf "\n"
            printf "  # Post an DELETE task to a Pilot Link Data Service\n"
            printf "  task_POST_pilot_link.sh -n namespace -p pilot-link-ds1 -o D -s b3bdbb197efd -f f05b173050084140aa40ed4875fb7e57\n"
            printf "\n"
            printf "Options:\n"
            printf "      -n, --namespace: Namespace of the Pilot Link Data Service. MUST be provided\n"
            printf "      -p, --pilotlink: The name (excluding Pod instance) of the Pilot Link Data Service to Post the task to. MUST be provided\n"
            printf "      -s, --srcuri: The source uri. MUST be provided\n"
            printf "      -d, --dsturi: The destination uri. MUST be provided\n"
            printf "      -o, --operation: The operation to perform. MUST be provided\n"
            printf "      -m, --mode: The mode to use for the operation. Defaults to ENTERPRISE_PERFORMANCE if not provided\n"
            printf "      -f, --filter: The filter to use for the operation. Default to * if not provided. MUST be a bundle Id for\n"
            printf "operations other than INGEST\n"
            printf "\n"
            printf "Usage:\n"
            printf "  task_POST_pilot_link.sh [options]\n"
            printf "\n"
            exit 1
            ;;
        -n|--namespace)
            NAMESPACE=$2
            shift
            shift
            ;;
        -p|--pilotlink)
            NAME=$2
            shift
            shift
            ;;
        -s|--srcuri)
            SRCURI=$2
            shift
            shift
            ;;
        -d|--dsturi)
            DSTURI=$2
            shift
            shift
            ;;
        -o|--operation)
            OPERATION=$2
            shift
            shift
            ;;
        -m|--mode)
            MODE=$2
            shift
            shift
            ;;
        -f|--filter)
            FILTER=$2
            shift
            shift
            ;;
        -*|--*)
            printf "ERROR: Unknown option $1\n"
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

if [[ $NAMESPACE == "" ]]
then
    printf "ERROR: A namespace must be specified\n"
    exit 1
fi

if [[ $NAME == "" ]]
then
    printf "ERROR: A Pilot Link Data Service name must be specified\n"
    exit 1
fi

if [[ $SRCURI == "" ]]
then
    printf "ERROR: A Source URI must be specified\n"
    exit 1
fi

if [[ $DSTURI == "" ]]
then
    case "$OPERATION" in
        "INGEST" | "COPY" | "EXPORT")
            printf "ERROR: A Destination URI must be specified\n"
            exit 1        
            ;;
        *)
            :
            ;;        
    esac
fi

if [[ $FILTER == "*" ]]
then
    case "$OPERATION" in
        "INGEST")
            :
            ;;
        *)
            printf "ERROR: A Bundle Id must be specified for the filter\n"
            exit 1
            ;;      
    esac
fi

case "$OPERATION" in
    "INGEST" | "COPY" | "EXPORT" | "DELETE" | "CHECK" | "TRUST")
        :
        ;;
    *)
        printf "ERROR: An Operation must be specified\n"
        exit 1
        ;;        
esac

namespace=$NAMESPACE
name=$NAME

declare -a UDS_POD_ARRAY

UDS_POD_ELEMS=$(kubectl get pod -n $namespace -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,IP:.status.podIP | grep $name-)

found=false
for UDS_POD_ELEM in $UDS_POD_ELEMS
do
    if [[ "$UDS_POD_ELEM" == "$NAME"* ]]
    then
        found=true
        break
    fi
done

if [ $found == false ]
then
    printf "ERROR: Pilot Link Data Service Pod not found\n"
    exit 1
fi

IDX=0
for UDS_POD_ELEM in $UDS_POD_ELEMS
do        
        UDS_POD_ARRAY[$IDX]=$UDS_POD_ELEM
        if [ $IDX == 2 ]
        then            
            printf "Task POST for ${UDS_POD_ARRAY[0]}/${UDS_POD_ARRAY[1]}\n"
            case "$OPERATION" in
                "INGEST")
                    OPERATION_JSON="{\"category\":\"$OPERATION\",\"destinationUri\":\"$DSTURI\",\"filter\":\"$FILTER\",\"sourceUri\":\"$SRCURI\",\"orchestrationMode\":\"$MODE\",\"userId\":\"k8s-incluster-script\",\"verify\":false}"
                    ;;
                "COPY" | "EXPORT")
                    OPERATION_JSON="{\"category\":\"$OPERATION\",\"destinationUri\":\"$DSTURI\",\"filter\":\"$FILTER\",\"sourceUri\":\"$SRCURI\",\"userId\":\"k8s-incluster-script\",\"verify\":false}"
                    ;;
                "DELETE" | "CHECK" | "TRUST")
                    OPERATION_JSON="{\"category\":\"$OPERATION\",\"filter\":\"$FILTER\",\"sourceUri\":\"$SRCURI\",\"userId\":\"k8s-incluster-script\",\"verify\":false}"
                    ;;        
            esac

            # Execute the data operation
            printf "Executing the $OPERATION data operation on ${UDS_POD_ARRAY[0]}/${UDS_POD_ARRAY[1]}\n"            
            RESPONSE=$(curl -s --insecure -X POST $HTTPS${UDS_POD_ARRAY[2]}:5000/$URL_END -H "accept: application/json" -H "Content-Type: application/json" -d $OPERATION_JSON)
            echo "$RESPONSE"
            OPERATION_TASK_ID=$(echo $RESPONSE | jq '.taskId')
            OPERATION_TASK_ID=$(echo "$OPERATION_TASK_ID" | tr -d '"')
            if [ $OPERATION == "INGEST" ]
            then
                OPERATION_SESSION_ID=$(echo $RESPONSE | jq '.sessionId')
                OPERATION_SESSION_ID=$(echo "$OPERATION_SESSION_ID" | tr -d '"')
            else
                OPERATION_SESSION_ID=$FILTER
            fi

            # Check if the operation was executed
            if [ $OPERATION_TASK_ID == null ]
            then
                printf "ERROR: Failed to execute the operation\n"
                exit 1
            fi

            printf "$OPERATION data operation Task Id : $OPERATION_TASK_ID\n"
            sleep 1

            # Wait for the task to complete
            while : ; do
                OPERATION_TASK_STATE=$(curl -s --insecure -X GET $HTTPS${UDS_POD_ARRAY[2]}:5000/$URL_END/$OPERATION_TASK_ID -H "accept: application/json" | jq '.state')
                if [ "$OPERATION_TASK_STATE" == "\"COMPLETE\"" ]
                then
                    printf "Task State $OPERATION_TASK_STATE\n"
                    break
                fi
                if [ "$OPERATION_TASK_STATE" == "\"FAILED\"" ]
                then
                    printf "Task State $OPERATION_TASK_STATE\n"
                    break
                fi
                printf "."
                sleep 1
            done

            # Display summary of the task operation
            printf "Summary of the $OPERATION data operation task $OPERATION_TASK_ID\n"
            curl -s --insecure -X GET $HTTPS${UDS_POD_ARRAY[2]}:5000/$URL_END/$OPERATION_TASK_ID/"Progress" -H "accept: application/json"

            IDX=0
        else
            ((IDX++))
        fi
done
