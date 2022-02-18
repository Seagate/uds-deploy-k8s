#!/bin/bash

BASE_PATH=$(dirname "$(realpath -s "$0")")
NAMESPACE="nostore1"
CREATE_COUNT=2
TYPE="no"
CFG_FILE="$BASE_PATH/cfg/pilot-link-ctrlr-config.json"
NODE_LABEL=""
LP_REGURL="notset"
LP_USERNAME="notset"
LP_PASSWORD=""

while [[ $# -gt 0 ]]
do
    case $1 in
        -n|--namespace)
            NAMESPACE=$2
            shift
            shift
            ;;
        -c|--count)
            CREATE_COUNT=$2
            shift
            shift
            ;;
        -t|--type)
            TYPE=$2
            shift
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
        -r|--regurl)
            LP_REGURL=$2
            shift
            shift
            ;;
        -u|--username)
            LP_USER=$2
            shift
            shift
            ;;
        -p|--password)
            LP_PASSWORD=$2
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

if [ "$LP_PASSWORD" == "" ]
then
    printf "Enter your Lyve Pilot user account password : \n"
    read -s LP_PASSWORD
fi

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
        --set pilotlinkctrlr.secret.lpregurl=$LP_REGURL \
        --set pilotlinkctrlr.secret.lpusername=$LP_USERNAME \
        --set pilotlinkctrlr.secret.lppassword=$LP_PASSWORD \
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
        --set pilotlinkctrlr.secret.lpregurl=$LP_REGURL \
        --set pilotlinkctrlr.secret.lpusername=$LP_USERNAME \
        --set pilotlinkctrlr.secret.lppassword=$LP_PASSWORD \
        --set-file pilotlinkctrlr.config.file=$CFG_FILE
fi
