#!/bin/bash

BASE_PATH=$(dirname "$(realpath -s "$0")")
NAMESPACE=""
TYPE="no"
CFG_FILE="$BASE_PATH/cfg/pilot-link-ctrlr-config.json"
NODE_LABEL=""
LP_PASSWORD=""

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
            printf "NOTE: A password will be asked for on execusion. This can be ignored if manual registration is being used\n"
            printf "\n"
            printf "Examples:\n"
            printf "  # Deploy a Pilot Link deployment with storage detection disabled\n"
            printf "  deploy_pilot_link.sh -n nostore1 -f pilot-link-config.json\n"
            printf "\n"
            printf "  # Deploy a Pilot Link deployment with storage detection enabled\n"
            printf "  deploy_pilot_link.sh -n detect1 -f pilot-link-config.json -d\n"
            printf "\n"
            printf "  # Deploy a Pilot Link deployment with storage detection enabled to a specific kubernetes node, where the label is not the same\n"
            printf "  as the namespace that is used\n"
            printf "  deploy_pilot_link.sh -n detect1 -f pilot-link-config.json -d -l pilotlinknodelabel\n"
            printf "\n"
            printf "Options:\n"
            printf "      -n, --namespace: The namespace for the deployment. The namespace will be created. This MUST be provided\n"
            printf "      -d, --detect: Enables storage detection on the kubernetes node. If not provide the storage detecion feature is disabled \n"
            printf "      -f, --file: The configuration file to use for the deployment. Defaults to cfg/pilot-link-ctrlr-config.json\n"
            printf "      -l, --label: The pilotLinkNodeLabel applied to a kubernetes node. This is used by \"detect\" to attach the deployment to the intended node\n"
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
        -d|--detect)
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
clusterrolebinding=$namespace"-pilot-link-ctrlr-rbac-binding"
name="pilot-link-ctrlr"

if [[ $namespace == "" ]]
then
    printf "ERROR: A namespace must be specified\n"
fi

printf "Enter your Lyve Pilot account password : "
read -s LP_PASSWORD
printf "\n"

if [ "$CFG_FILE" == "" ] || [ ! -e $CFG_FILE ]
then
    printf "ERROR: Configuration file does not exist\n"
    exit 1
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
    pv_storage_name=$namespace"-pilot-link-ctrlr-hostpath"
    pv_storage_hostpath="/mnt/pilot-link/storage/"$namespace
    pv_hostdevices_name=$namespace"-pilot-link-ctrlr-hostdevices"
    pv_hostsys_name=$namespace"-pilot-link-ctrlr-hostsys"
    
    printf "Creating $namespace-$name\n"
    helm install $namespace"-"$name $BASE_PATH/helm_pkg/pilot-link-ctrlr \
        --set pilotlinkctrlr.clusterrolebinding.name=$clusterrolebinding \
        --set namespace=$namespace \
        --set pilotlinkctrlr.pod.image=$PILOT_LINK_CTRLR_IMAGE \
        --set pilotlinkctrlr.nodeselector.pilotlinknodelabel=$pilotlinknodelabel \
        --set pilotlinkctrlr.pv.storage.name=$pv_storage_name \
        --set pilotlinkctrlr.pv.storage.hostpath=$pv_storage_hostpath \
        --set pilotlinkctrlr.pv.hostdevices.name=$pv_hostdevices_name \
        --set pilotlinkctrlr.pv.hostsys.name=$pv_hostsys_name \
        --set pilotlinkctrlr.dataservices.type=$TYPE \
        --set pilotlinkctrlr.dataservices.image=$PILOT_LINK_DS_IMAGE \
        --set pilotlinkctrlr.secret.lppassword=$LP_PASSWORD \
        --set-file pilotlinkctrlr.config.file=$CFG_FILE
else
    printf "Creating $namespace-$name\n"
    helm install $namespace"-"$name $BASE_PATH/helm_pkg/pilot-link-ctrlr \
        --set pilotlinkctrlr.clusterrolebinding.name=$clusterrolebinding \
        --set namespace=$namespace \
        --set pilotlinkctrlr.pod.image=$PILOT_LINK_CTRLR_IMAGE \
        --set pilotlinkctrlr.dataservices.type=$TYPE \
        --set pilotlinkctrlr.dataservices.image=$PILOT_LINK_DS_IMAGE \
        --set pilotlinkctrlr.secret.lppassword=$LP_PASSWORD \
        --set-file pilotlinkctrlr.config.file=$CFG_FILE
fi
