 #!/bin/bash

NAMESPACE=""

while [[ $# -gt 0 ]]
do
    case $1 in
        -n|--namespace)
            NAMESPACE=$2
            shift
            shift
            ;;
        -f|--file)
            CFG_FILE=$2
            shift
            shift
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}"

NAME=${1:-"pilot-link-"}

namespace=$NAMESPACE
name=$NAME

declare -a DEPLOYMENT_ARRAY

if [[ $namespace == "" ]]
then    
    DEPOLYMENT_ELEMS=$(kubectl get deployments -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name -A | grep $name)
else
    DEPOLYMENT_ELEMS=$(kubectl get deployments -n $namespace -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name | grep $name)
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
