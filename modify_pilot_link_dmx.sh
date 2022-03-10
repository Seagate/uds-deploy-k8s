 #!/bin/bash

NAMESPACE=""
DMX_FILE=""
DMX_ENABLED="false"

while [[ $# -gt 0 ]]
do
    case $1 in
        -h|--help)
            printf "Modifies a previously deployed Pilot Link deployment's Pilot Link DMX configuration\n"
            printf "\n"
            printf "Examples:\n"
            printf "\n"
            printf "  # Modify the configuration for a Pilot Link DMX in specified namespace\n"
            printf "  modify_pilot_link_dmx.sh -n namespace -d dmx.tar.gz\n"
            printf "  # Remove the configuration for a Pilot Link DMX in specified namespace\n"
            printf "  modify_pilot_link_dmx.sh -n namespace\n"
            printf "\n"
            printf "Options:\n"
            printf "      -n, --namespace: The namespace of the deployment. This MUST be provided\n"
            printf "      -d, --dmx: Enables the DMX feature. If not provided the DMX feature is disabled. A tar.gz file with the DMX scripts and config file MUST be provided\n"
            printf "\n"
            printf "Usage:\n"
            printf "  modify_pilot_link_dmx.sh -n namespace [options]\n"
            printf "\n"
            exit 1
            ;;
        -n|--namespace)
            NAMESPACE=$2
            shift
            shift
            ;;
        -d|--dmx)
            DMX_FILE=$2
            DMX_ENABLED="true"
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
name_dmx="pilot-link-dmx-cfg"

if [[ $namespace == "" ]]
then
    printf "ERROR: A namespace must be specified\n"
    exit 1
fi

if [ "$DMX_ENABLED" == "true" ]
then
    if [ "$DMX_FILE" == "" ] || [ ! -e $DMX_FILE ]
    then
        printf "ERROR: DMX file does not exist\n"
        exit 1
    fi
fi

STATUS=$(kubectl get configmap -n $namespace $name_dmx 2>&1)
if [[ "$STATUS" == "Error"* ]]
then
    printf "ERROR: $namespace/$name_dmx not found\n"
    exit 1
fi

printf "Applying DMX modification to $namespace/$name_dmx"
if [ "$DMX_ENABLED" == "true" ]
then
    kubectl create configmap -n $namespace $name_dmx --from-file $DMX_FILE -o yaml --dry-run=client | kubectl replace -f -
else
    kubectl create configmap -n $namespace $name_dmx -o yaml --dry-run=client | kubectl replace -f -
fi
printf "DMX modification complete for $namespace/$name_dmx\n"
