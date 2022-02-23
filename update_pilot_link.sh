#!/bin/bash

NAMESPACE=""

while [[ $# -gt 0 ]]
do
    case $1 in
        -h|--help)
            printf "Udpate a Pilot Link deployment with specified container images. Both Pilot Link\n"
            printf "Controller and Data Services can be updated\n"
            printf "\n"
            printf "The container image locations are specified using the environment variables\n"
            printf "prior to running the script:\n"
            printf "  export PILOT_LINK_DS_IMAGE=mycontaineregistry/udspilotlinkds:x.x.x\n"
            printf "  export PILOT_LINK_CTRLR_IMAGE=mycontaineregistry/udspilotlinkctrlr:x.x.x\n"
            printf "\n"
            printf "Examples:\n"
            printf "  # Udpate a Pilot Link deployment with the specified namespace\n"
            printf "  update_pilot_link.sh -n namespace\n"
            printf "\n"
            printf "  # Udpates all Pilot Link deployments in the kubernetes cluster\n"
            printf "  update_pilot_link.sh\n"
            printf "\n"
            printf "Options:\n"
            printf "      -n, --namespace: The optional namespace to update. If no namespace\n"
            printf "is provided all deployment will be udpated\n"
            printf "\n"
            printf "Usage:\n"
            printf "  update_pilot_link.sh [options]\n"
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

name="pilot-link-ctrlr"

if [[ -z "${PILOT_LINK_CTRLR_IMAGE}" ]]
then
    printf "ERROR: No Pilot Link Controller image specified. Export the env variable PILOT_LINK_CTRLR_IMAGE with image to use\n"
    exit 1
fi

if [[ -z "${PILOT_LINK_DS_IMAGE}" ]]
then
    printf "ERROR: No Pilot Link Data Service image specified. Export the env variable PILOT_LINK_DS_IMAGE with image to use\n"
    exit 1
fi

if [[ $NAMESPACE == "" ]]
then
    NAMESPACES=$(kubectl get deployments -A | grep $name | cut -f1 -d " ")
else
    NAMESPACES=$(kubectl get deployments -A | grep $NAMESPACE | grep $name | cut -f1 -d " ")
fi

for namespace in $NAMESPACES
do
    STATUS=$(kubectl get deployment -n $namespace $name 2>&1)
    if [[ "$STATUS" == "Error"* ]]
    then
        printf "ERROR: $namespace/$name not found\n"
        exit 1
    fi

    printf "Setting the Data Service image to $PILOT_LINK_DS_IMAGE\n"
    kubectl set env -n $namespace deployment/$name PILOT_LINK_DS_IMAGE=$PILOT_LINK_DS_IMAGE > /dev/null

    printf "Setting the image for $namespace/$name to $PILOT_LINK_CTRLR_IMAGE\n"
    kubectl set image -n $namespace deployment/$name $name=$PILOT_LINK_CTRLR_IMAGE

    printf "Waiting for the update to be rolled out for $namespace/$name\n"
    while true
    do
        printf "."
        STATUS=$(kubectl rollout status -n $namespace deployment/$name)
        if [[ "$STATUS" == "deployment \"$name\" successfully rolled out" ]]
        then
            printf "\nUpdate rollout was successful for $namespace/$name\n"
            break
        fi
        sleep 1
    done
done
