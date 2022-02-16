 #!/bin/bash

NAMESPACE=${1:-""}
CFG_FILE=${2:-""}

namespace=$NAMESPACE
name="pilot-link-ctrlr"

if [[ $namespace == "" ]]
then
    printf "ERROR: A namespace must be specified\n"
fi

if [ "$CFG_FILE" == "" ] || [ ! -e $CFG_FILE ]
then
    printf "ERROR: Configuration file does not exist\n"
    exit 1
fi

STATUS=$(kubectl get deployment -n $namespace $name 2>&1)
if [[ "$STATUS" == "Error"* ]]
then
    printf "ERROR: $namespace/$name not found\n"
    exit 1
fi

CFG_CONTENT=$(cat $CFG_FILE)

printf "Modifying the configuration for $namespace/$name"
kubectl create configmap -n $namespace $name-cfg --from-literal=pilot-link-ctrlr-config.json="$CFG_CONTENT" -o yaml --dry-run=client | kubectl replace -f -

printf "Applying configuration to $namespace/$name\n"
POD_NAME=$(kubectl get pod -n $namespace | grep $name | cut -f1 -d " ")
kubectl delete pod -n $namespace $POD_NAME
printf "Configuration modification complete for $namespace/$name\n"
