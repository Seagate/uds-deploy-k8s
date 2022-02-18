 #!/bin/bash

NAMESPACE=""

while [[ $# -gt 0 ]]
do
    case $1 in
        -h|--help)
            printf "Destroys previously deployed Pilot Link deployments\n"
            printf "\n"
            printf "Examples:\n"
            printf "  # Destory a Pilot Link deployment with the specified namespace\n"
            printf "  destroy_pilot_link.sh -n namespace\n"
            printf "\n"
            printf "  # Destroy all Pilot Link deployments in the kubernetes cluster\n"
            printf "  destroy_pilot_link.sh\n"
            printf "\n"
            printf "Options:\n"
            printf "      -n, --namespace: The optional namespace to destroy. If no namespace\n"
            printf "is provided all deployments will be destroyed\n"
            printf "\n"
            printf "Usage:\n"
            printf "  destroy_pilot_link.sh [options]\n"
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

namespace=$NAMESPACE
name="pilot-link-ctrlr"

if [[ $namespace == "" ]]
then
    FILTER=$name
else
    FILTER=$namespace"-"$name
fi

UDS_HELM_CHARTS=$(helm ls | grep $FILTER | cut -f1)
for UDS_HELM_CHART in $UDS_HELM_CHARTS
do
    printf "Removing $UDS_HELM_CHART\n"
    helm uninstall $UDS_HELM_CHART
done
