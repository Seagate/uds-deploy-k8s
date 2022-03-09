#!/bin/bash

BASE_PATH=$(dirname "$(realpath -s "$0")")
NAMESPACE=""
TYPE="no"
CFG_FILE="$BASE_PATH/cfg/pilot-link-ctrlr-config.json"
NODE_LABEL=""
LP_PASSWORD=""
DMX_FILE=""
DMX_ENABLED="no"

while [[ $# -gt 0 ]]
do
    case $1 in
        -h|--help)
            printf "Deploy a Pilot Link deployment with specified container images. Both Pilot Link\n"
            printf "Controller and Data Services need to be provided\n"
            printf "\n"
            printf "The container image locations are specified using the environment variables\n"
            printf "prior to running the script:\n"
            printf "  export PILOT_LINK_DS_IMAGE=mycontaineregistry/udspilotlinkds:x.x.x\n"
            printf "  export PILOT_LINK_CTRLR_IMAGE=mycontaineregistry/udspilotlinkctrlr:x.x.x\n"
            printf "\n"
            printf "NOTE: A password will be asked for on execution. This can be ignored if manual registration is being used\n"
            printf "\n"
            printf "Examples:\n"
            printf "  # Deploy a Pilot Link deployment with storage detection disabled\n"
            printf "  deploy_pilot_link.sh -n nostore1 -f pilot-link-config.json\n"
            printf "\n"
            printf "  # Deploy a Pilot Link deployment with storage detection enabled\n"
            printf "  deploy_pilot_link.sh -n detect1 -f pilot-link-config.json -s\n"
            printf "\n"
            printf "  # Deploy a Pilot Link deployment with storage detection enabled to a specific kubernetes node, where the label is not the same\n"
            printf "  as the namespace that is used\n"
            printf "  deploy_pilot_link.sh -n detect1 -f pilot-link-config.json -s -l pilotlinknodelabel\n"
            printf "\n"
            printf "  # Deploy a Pilot Link deployment with DMX enabled. The user MUST provide a directory with the files for the DMX configuration\n"
            printf "  deploy_pilot_link.sh -n dmx1 -d dmx.tar.gz\n"
            printf "\n"
            printf "Options:\n"
            printf "      -n, --namespace: The namespace for the deployment. The namespace will be created. This MUST be provided\n"
            printf "      -s, --storedetect: Enables storage detection on the kubernetes node. If not provide the storage detection feature is disabled\n"
            printf "      -f, --file: The configuration file to use for the deployment. Defaults to cfg/pilot-link-ctrlr-config.json\n"
            printf "      -l, --label: The pilotLinkNodeLabel applied to a kubernetes node. This is used by -s,--storedetect to attach the deployment to the intended node\n"
            printf "      -d, --dmx: Enables the DMX feature. If not provide the DMX feature is disabled. A tar.gz file with the DMX scripts and config file MUST be provided\n"
            printf "for storage detection. Assumes pilotLinkNodeLabel is set as the same as the namespace if not provided\n"
            printf "\n"
            printf "Usage:\n"
            printf "  deploy_pilot_link.sh -n namespace [options]\n"
            printf "\n"
            exit 1
            ;;
        -n|--namespace)
            NAMESPACE=$2
            shift
            shift
            ;;
        -s|--storedetect)
            TYPE="detect"
            shift
            ;;
        -f|--file)
            CFG_FILE=$2
            shift
            shift
            ;;
        -l|--label)
            NODE_LABEL=$2
            shift
            shift
            ;;
        -d|--dmx)
            DMX_FILE=$2
            DMX_ENABLED="yes"
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
name_dmx="pilot-link-dmx-cfg"

if [[ $namespace == "" ]]
then
    printf "ERROR: A namespace must be specified\n"
    exit 1
fi

printf "Enter your Lyve Pilot account password : "
read -s LP_PASSWORD
printf "\n"

if [ "$LP_PASSWORD" == "" ]
then
    LP_PASSWORD="notset"
fi

if [ "$CFG_FILE" == "" ] || [ ! -e $CFG_FILE ]
then
    printf "ERROR: Configuration file does not exist\n"
    exit 1
fi

if [ "$DMX_ENABLED" == "yes" ]
then
    if [ "$DMX_FILE" == "" ] || [ ! -e $DMX_FILE ]
    then
        printf "ERROR: DMX file does not exist\n"
        exit 1
    fi
fi

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

pilotlinknodelabel=$NODE_LABEL
if [[ $pilotlinknodelabel == "" ]]
then
    pilotlinknodelabel=$namespace
fi

if [[ $TYPE == "detect" ]]
then
    printf "Creating $namespace-$name\n"
    helm install $namespace"-"$name $BASE_PATH/helm_pkg/pilot-link-ctrlr \
        --set namespace=$namespace \
        --set pilotlinkctrlr.pod.image=$PILOT_LINK_CTRLR_IMAGE \
        --set pilotlinkctrlr.nodeselector.pilotlinknodelabel=$pilotlinknodelabel \
        --set pilotlinkctrlr.dataservices.type=$TYPE \
        --set pilotlinkctrlr.dataservices.dmx.enabled=$DMX_ENABLED \
        --set pilotlinkctrlr.dataservices.image=$PILOT_LINK_DS_IMAGE \
        --set pilotlinkctrlr.secret.lppassword=$LP_PASSWORD \
        --set-file pilotlinkctrlr.config.file=$CFG_FILE
else
    printf "Creating $namespace-$name\n"
    helm install $namespace"-"$name $BASE_PATH/helm_pkg/pilot-link-ctrlr \
        --set namespace=$namespace \
        --set pilotlinkctrlr.pod.image=$PILOT_LINK_CTRLR_IMAGE \
        --set pilotlinkctrlr.dataservices.type=$TYPE \
        --set pilotlinkctrlr.dataservices.dmx.enabled=$DMX_ENABLED \
        --set pilotlinkctrlr.dataservices.image=$PILOT_LINK_DS_IMAGE \
        --set pilotlinkctrlr.secret.lppassword=$LP_PASSWORD \
        --set-file pilotlinkctrlr.config.file=$CFG_FILE
fi

if [ "$DMX_ENABLED" == "yes" ]
then
    while true
    do
        RESULT=$(kubectl get namespaces | grep -w $namespace)
        if [[ "$RESULT" != "" ]]
        then
            break
        fi
        sleep 1
    done

    printf "Creating $namespace-$name_dmx\n"
    kubectl create configmap -n $namespace $name_dmx --from-file $DMX_FILE
fi
