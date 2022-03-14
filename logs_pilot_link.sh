 #!/bin/bash

NAMESPACE=""

while [[ $# -gt 0 ]]
do
    case $1 in
        -h|--help)
            printf "Dumps the logs for previously deployed Pilot Link deployments\n"
            printf "\n"
            printf "Examples:\n"
            printf "\n"
            printf "  # Dump all logs for the Pilot Link deployment with the specified namespace\n"
            printf "  logs_pilot_link.sh -n namespace\n"
            printf "\n"
            printf "  # Dump all logs for Pilot Link deployments in the kubernetes cluster\n"
            printf "  logs_pilot_link.sh\n"
            printf "\n"
            printf "Options:\n"
            printf "      -n, --namespace: The optional namespace to dump the logs for. If no namespace is\n"
            printf "provided logs will be dumped for all deployments\n"
            printf "\n"
            printf "Usage:\n"
            printf "  logs_pilot_link.sh [options]\n"
            printf "\n"
            exit 1
            ;;
        -n|--namespace)
            NAMESPACE=$2
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

set -- "${POSITIONAL_ARGS[@]}"

namespace=$NAMESPACE
name_all="pilot-link-"
name_ctrlr="pilot-link-ctrlr"

if [[ $namespace == "" ]]
then
    DEPOLYMENT_ELEMS=$(kubectl get deployments -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name -A | grep $name_ctrlr)
else
    DEPOLYMENT_ELEMS=$(kubectl get deployments -n $namespace -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name | grep $name_ctrlr)
fi

IDX=0
for DEPOLYMENT_ELEM in $DEPOLYMENT_ELEMS
do
    if [ $IDX == 0 ]
    then
        printf "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
        printf "START of get for $DEPOLYMENT_ELEM\n"
        printf "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
        kubectl get serviceaccounts,networkpolicy,deployments,replicasets,pods,services,configmaps,secrets,pvc,pv -n $DEPOLYMENT_ELEM -o wide
        printf "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
        printf "END of get for $DEPOLYMENT_ELEM\n"
        printf "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
        printf "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
        printf "START of describe for $DEPOLYMENT_ELEM\n"
        printf "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
        kubectl describe serviceaccounts,networkpolicy,deployments,replicasets,pods,services,configmaps,secrets,pvc,pv -n $DEPOLYMENT_ELEM
        printf "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
        printf "END of describe for $DEPOLYMENT_ELEM\n"
        printf "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
        ((IDX++))
    else
        IDX=0
    fi
done

declare -a DEPLOYMENT_ARRAY

if [[ $namespace == "" ]]
then    
    DEPOLYMENT_ELEMS=$(kubectl get deployments -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name -A | grep $name_all)
else
    DEPOLYMENT_ELEMS=$(kubectl get deployments -n $namespace -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name | grep $name_all)
fi

IDX=0
for DEPOLYMENT_ELEM in $DEPOLYMENT_ELEMS
do        
        DEPLOYMENT_ARRAY[$IDX]=$DEPOLYMENT_ELEM
        if [ $IDX == 1 ]
        then
            printf "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
            printf "START of logs for ${DEPLOYMENT_ARRAY[0]}/${DEPLOYMENT_ARRAY[1]}\n"
            printf "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
            kubectl logs -n ${DEPLOYMENT_ARRAY[0]} deployment/${DEPLOYMENT_ARRAY[1]} --tail=-1
            printf "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
            printf "END of logs for ${DEPLOYMENT_ARRAY[0]}/${DEPLOYMENT_ARRAY[1]}\n"
            printf "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
            IDX=0
        else
            ((IDX++))
        fi
done
