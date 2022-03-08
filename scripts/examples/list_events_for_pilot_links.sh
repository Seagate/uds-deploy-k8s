#!/bin/bash

HTTPS="https://"
URL_END="uds/v1/events"

declare -a UDS_POD_ARRAY

UDS_POD_ELEMS=$(kubectl get pod -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,IP:.status.podIP -A | grep pilot-link-ds)
IDX=0
for UDS_POD_ELEM in $UDS_POD_ELEMS
do        
        UDS_POD_ARRAY[$IDX]=$UDS_POD_ELEM
        if [ $IDX == 2 ]
        then
            printf "Events for ${UDS_POD_ARRAY[0]}/${UDS_POD_ARRAY[1]}\n"
            curl --insecure -X GET $HTTPS${UDS_POD_ARRAY[2]}:5000/$URL_END -H  "accept: application/json" -H  "Content-Type: application/json" -d "{}"
            IDX=0
        else
            ((IDX++))
        fi
done