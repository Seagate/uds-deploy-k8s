 #!/bin/bash

FILTER=${1:-"pilot-link-ctrlr"}

UDS_HELM_CHARTS=$(helm ls | grep $FILTER | cut -f1)
for UDS_HELM_CHART in $UDS_HELM_CHARTS
do
    printf "Removing $UDS_HELM_CHART\n"
    helm uninstall $UDS_HELM_CHART
done
