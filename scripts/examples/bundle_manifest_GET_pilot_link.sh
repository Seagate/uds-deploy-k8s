#!/bin/bash

HTTPS="https://"
URL_END="uds/v1/bundle"

NAMESPACE=""
VOLUME=""
BUNDLE=""

while [[ $# -gt 0 ]]
do
    case $1 in
        -h|--help)
            printf "Get the Manifest for a Bundle on a Pilot Link Data Service Volume\n"
            printf "\n"
            printf "Examples:\n"
            printf "  # Get the Bundle Information for Pilot Link Data Services with the specified namespace\n"
            printf "  bundle_manifest_GET_pilot_link.sh -n namespace -p pilot-link-ds1 -v ef77b5e3-08e6-3c66-912a-502e652b081c -b 20a3569b9e3b47e298c52340f8ff36e0\n"
            printf "\n"
            printf "Options:\n"
            printf "      -n, --namespace: Namespace of the Pilot Link Data Service. MUST be provided\n"
            printf "      -p, --pilotlink: The name (excluding Pod instance) of the Pilot Link Data Service the Bundle resides on. MUST be provided\n"
            printf "      -v, --volumeid: The volume the Bundle resides on. MUST be provided\n"
            printf "      -b, --bundleid: The bundle to get the Manifest for. MUST be provided\n"
            printf "\n"
            printf "Usage:\n"
            printf "  bundle_manifest_GET_pilot_link.sh [options]\n"
            printf "\n"
            exit 1
            ;;
        -n|--namespace)
            NAMESPACE=$2
            shift
            shift
            ;;
        -p|--pilotlink)
            NAME=$2
            shift
            shift
            ;;
        -v|--volumeid)
            VOLUME=$2
            shift
            shift
            ;;
        -b|--bundleid)
            BUNDLE=$2
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

if [[ $NAMESPACE == "" ]]
then
    printf "ERROR: A namespace must be specified\n"
    exit 1
fi

if [[ $NAME == "" ]]
then
    printf "ERROR: A Pilot Link Data Service name must be specified\n"
    exit 1
fi

if [[ $VOLUME == "" ]]
then
    printf "ERROR: A Volume Id must be specified\n"
    exit 1
fi

if [[ $BUNDLE == "" ]]
then
    printf "ERROR: A Bundle Id must be specified\n"
    exit 1
fi

namespace=$NAMESPACE
name=$NAME

declare -a UDS_POD_ARRAY

UDS_POD_ELEMS=$(kubectl get pod -n $namespace -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,IP:.status.podIP | grep $name-)

found=false
for UDS_POD_ELEM in $UDS_POD_ELEMS
do
    if [[ "$UDS_POD_ELEM" == "$NAME"* ]]
    then
        found=true
        break
    fi
done

if [ $found == false ]
then
    printf "Pilot Link Data Service Pod not found\n"
    exit 1
fi

IDX=0
for UDS_POD_ELEM in $UDS_POD_ELEMS
do        
        UDS_POD_ARRAY[$IDX]=$UDS_POD_ELEM
        if [ $IDX == 2 ]
        then
            printf "Bundle GET for ${UDS_POD_ARRAY[0]}/${UDS_POD_ARRAY[1]}\n"
            OUTPUT=$(curl -s --insecure -X GET $HTTPS${UDS_POD_ARRAY[2]}:5000/$URL_END/$VOLUME/$BUNDLE/Manifest -H  "accept: application/json" -H  "Content-Type: application/json" -d "{}")
            
            echo "$OUTPUT"
            
            IDX=0
        else
            ((IDX++))
        fi
done
