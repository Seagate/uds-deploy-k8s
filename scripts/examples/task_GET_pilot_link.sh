#!/bin/bash

HTTPS="https://"
URL_END="uds/v1/task"

NAMESPACE=""
VERBOSE=false

while [[ $# -gt 0 ]]
do
    case $1 in
        -h|--help)
            printf "Get the Task Information for Pilot Link Data Services\n"
            printf "\n"
            printf "Examples:\n"
            printf "  # Get the Task Information for Pilot Link Data Services with the specified namespace\n"
            printf "  task_GET_pilot_link.sh -n namespace\n"
            printf "\n"
            printf "  # Get the Volume Information for Pilot Link Data Services in the kubernetes cluster\n"
            printf "  task_GET_pilot_link.sh\n"
            printf "\n"
            printf "Options:\n"
            printf "      -n, --namespace: The optional namespace get information for. If no namespace\n"
            printf "is provided all Pilot Link Data Services Task Information will be shown\n"
            printf "      -v, --verbose: Display verbose output. If not provided only important fields will be\n"
            printf "displayed\n"
            printf "\n"
            printf "Usage:\n"
            printf "  task_GET_pilot_link.sh [options]\n"
            printf "\n"
            exit 1
            ;;
        -n|--namespace)
            NAMESPACE=$2
            shift
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
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

namespace=$NAMESPACE
verbose=$VERBOSE
declare -a UDS_POD_ARRAY

if [[ $namespace == "" ]]
then
    UDS_POD_ELEMS=$(kubectl get pod -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,IP:.status.podIP -A | grep pilot-link-ds)
else
    UDS_POD_ELEMS=$(kubectl get pod -n $namespace -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,IP:.status.podIP | grep pilot-link-ds)
fi

IDX=0
for UDS_POD_ELEM in $UDS_POD_ELEMS
do        
        UDS_POD_ARRAY[$IDX]=$UDS_POD_ELEM
        if [ $IDX == 2 ]
        then
            printf "Task GET for ${UDS_POD_ARRAY[0]}/${UDS_POD_ARRAY[1]}\n"
            OUTPUT=$(curl -s --insecure -X GET $HTTPS${UDS_POD_ARRAY[2]}:5000/$URL_END -H  "accept: application/json" -H  "Content-Type: application/json" -d "{}")
            
            if [ $verbose  == true ]
            then
                echo "$OUTPUT"
            else
                printf "[\n"
                echo "$OUTPUT" | grep -E "{|}|\"category\"|\"taskId\"|\"sessionId\"|\"filter\"|\"destinationUri\"|\"sourceUri\"" | grep -v "     \"name\""
                printf "]\n"
            fi

            IDX=0
        else
            ((IDX++))
        fi
done
