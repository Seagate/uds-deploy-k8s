#!/bin/bash

BASE_PATH=$(dirname "$(realpath -s "$0")")
NAMESPACE=${1:-"nostore1"}
CREATE_COUNT=${2:-2}
TYPE=${3:-"no"}
CFG_FILE=${4:-"$BASE_PATH/cfg/pilot-link-ctrlr-config.json"}
NODE_LABEL=${5:-""}

namespace=$NAMESPACE
clusterrolebinding=$namespace"-pilot-link-ctrlr-rbac-binding"
name="pilot-link-ctrlr"

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

if [[ $TYPE == "no" ]]
then
    printf "Creating $namespace-$name\n"
    helm install $namespace"-"$name $BASE_PATH/helm_pkg/pilot-link-ctrlr \
        --set pilotlinkctrlr.clusterrolebinding.name=$clusterrolebinding \
        --set namespace=$namespace \
        --set pilotlinkctrlr.pod.image=$PILOT_LINK_CTRLR_IMAGE \
        --set pilotlinkctrlr.dataservices.numof=$CREATE_COUNT \
        --set pilotlinkctrlr.dataservices.type=$TYPE \
        --set pilotlinkctrlr.dataservices.image=$PILOT_LINK_DS_IMAGE \
        --set-file pilotlinkctrlr.config.file=$CFG_FILE
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
        --set pilotlinkctrlr.dataservices.numof=$CREATE_COUNT \
        --set pilotlinkctrlr.dataservices.type=$TYPE \
        --set pilotlinkctrlr.dataservices.image=$PILOT_LINK_DS_IMAGE \
        --set-file pilotlinkctrlr.config.file=$CFG_FILE
fi
