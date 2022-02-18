 #!/bin/bash

NAMESPACE=""
CFG_FILE=""

while [[ $# -gt 0 ]]
do
    case $1 in
        -h|--help)
            printf "Modifies a previously deployed Pilot Link deployment's Pilot Link controller configuration\n"
            printf "\n"
            printf "Examples:\n"
            printf "\n"
            printf "  # Modify the configuration for a Pilot Link controller in specified namespace\n"
            printf "  modify_pilot_link.sh -n namespace -f config-file.json\n"
            printf "\n"
            printf "Options:\n"
            printf "      -n, --namespace: The namespace of the deployment. This MUST be provided\n"
            printf "      -f, --file: The configuration file to use to modify the deployment. This MUST be provided\n"
            printf "\n"
            printf "Usage:\n"
            printf "  modify_pilot_link.sh -n namespace -f config-file.json\n"
            printf "\n"
            exit 1
            ;;
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
kubectl rollout restart -n $namespace deployment/$name
printf "Configuration modification complete for $namespace/$name\n"
