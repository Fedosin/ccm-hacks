#!/bin/bash

set -e

help() {
    echo "Build a release image with custom CCM components and upload it to quay.io"
    echo ""
    echo "Usage: ./build_release_image.sh [options] -u <quay.io username>"
    echo "Options:"
    echo "-h, --help      show this message"
    echo "-u, --username  registered username in quay.io"    
    echo "-t, --tag       push to a custom tag in your origin release image repo, default: latest"
    echo "-r, --release   openshift release version, default: 4.8"
    echo "-a, --auth      path of registry auth file, default: ./config.json"
    echo "--cccmo         custom cluster-cloud-controller-manager-operator image name, default: quay.io/openshift/origin-cluster-cloud-controller-manager-operator:$RELEASE"
    echo "--aws-ccm       custom aws cloud-controller-manager image name, default: quay.io/openshift/origin-aws-cloud-controller-manager:$RELEASE"
    echo "--azure-ccm     custom azure cloud-controller-manager image name, default: quay.io/openshift/origin-azure-cloud-controller-manager:$RELEASE"
    echo "--azure-node    custom azure node manager image name, default: quay.io/openshift/origin-azure-cloud-node-manager:$RELEASE"
    echo "--openstack-ccm custom openstack cloud-controller-manager image name, default: quay.io/openshift/origin-openstack-cloud-controller-manager:$RELEASE"
    echo "--kapio         custom kube-apiserver-operator image name, default: current kube-apiserver-operator image from the release payload"
    echo "--kcmo          custom kube-controller-manager-operator image name, default: current kube-controller-manager-operator image from the release payload"
    echo "--mco           custom machine-config-operator image name, default: current machine-config-operator image from the release payload"
}

: ${GOPATH:=${HOME}/go}
: ${TAG:="latest"}
: ${RELEASE:="4.8"}
: ${OC_REGISTRY_AUTH_FILE:="config.json"}
: ${CCCMO_IMAGE:="quay.io/openshift/origin-cluster-cloud-controller-manager-operator:$RELEASE"}
: ${AWSCCM_IMAGE:="quay.io/openshift/origin-aws-cloud-controller-manager:$RELEASE"}
: ${AZURECCM_IMAGE:="quay.io/openshift/origin-azure-cloud-controller-manager:$RELEASE"}
: ${AZURENODE_IMAGE:="quay.io/openshift/origin-azure-cloud-node-manager:$RELEASE"}
: ${OCCM_IMAGE:="quay.io/openshift/origin-openstack-cloud-controller-manager:$RELEASE"}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            help
            exit 0
            ;;
            
        -u|--username)
            USERNAME=$2
            shift 2
            ;;

        -t|--tag)
            TAG=$2
            shift 2
            ;;

        -r|--release)
            RELEASE=$2
            shift 2
            ;;

        -a|--auth)
            OC_REGISTRY_AUTH_FILE=$2
            shift 2
            ;;

        --cccmo)
            CCCMO_IMAGE=$2
            shift 2
            ;;

        --aws-ccm)
            AWSCCM_IMAGE=$2
            shift 2
            ;;

        --azure-ccm)
            AZURECCM_IMAGE=$2
            shift 2
            ;;

        --azure-node)
            AZURENODE_IMAGE=$2
            shift 2
            ;;

        --openstack-ccm)
            OCCM_IMAGE=$2
            shift 2
            ;;

        --kapio)
            KAPIO_IMAGE=$2
            shift 2
            ;;

        --kcmo)
            KCMO_IMAGE=$2
            shift 2
            ;;

        --mco)
            MCO_IMAGE=$2
            shift 2
            ;;

        *)
            echo "Invalid option $1"
            help
            exit 1
            ;;
    esac
done

if [ -z "$USERNAME" ]; then
    echo "-u/--username was not provided, exiting ..."
    exit 1
fi

if [ ! -f "$OC_REGISTRY_AUTH_FILE" ]; then
    echo "$OC_REGISTRY_AUTH_FILE not found, exiting ..."
    exit 1
fi

PREFIX="Pull From: "
DEST_IMAGE="quay.io/$USERNAME/origin-release:$TAG"
FROM_IMAGE=$(curl -s  https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp-dev-preview/latest-$RELEASE/release.txt | grep "$PREFIX" | sed -e "s/^$PREFIX//")

echo "Start building local release image"

oc adm release new \
    --registry-config="$OC_REGISTRY_AUTH_FILE" \
    --from-release="$FROM_IMAGE" \
    --to-file="origin-release.tar" \
    --server https://api.ci.openshift.org \
    -n openshift \
    cluster-cloud-controller-manager-operator=$CCCMO_IMAGE \
    openstack-cloud-controller-manager=$OCCM_IMAGE \
    aws-cloud-controller-manager=$AWSCCM_IMAGE \
    azure-cloud-node-manager=$AZURENODE_IMAGE \
    azure-cloud-controller-manager=$AZURECCM_IMAGE \
    `[ ! -z "$KAPIO_IMAGE" ] && echo cluster-kube-apiserver-operator=$KAPIO_IMAGE` \
    `[ ! -z "$KCMO_IMAGE" ] && echo cluster-kube-controller-manager-operator=$KCMO_IMAGE` \
    `[ ! -z "$MCO_IMAGE" ] && echo machine-config-operator=$MCO_IMAGE`

echo "Local release image is saved to $PWD/origin-release.tar"

docker import origin-release.tar $DEST_IMAGE

docker push $DEST_IMAGE

rm -f origin-release.tar

echo "Successfully pushed $DEST_IMAGE"

echo "Testing release image"
docker pull $DEST_IMAGE
echo "$DEST_IMAGE image was tested, you can now deploy with the following command:"
echo "OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=$DEST_IMAGE openshift-install create cluster (...)"
