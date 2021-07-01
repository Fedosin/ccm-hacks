#!/bin/bash

set -e

help() {
    echo "Build a release image with specific changes to enable external cloud provider and upload it to quay.io"
    echo ""
    echo "Usage: ./build_all.sh [options] -u <quay.io username>"
    echo "Options:"
    echo "-h, --help      show this message"
    echo "-u, --username  registered username in quay.io"    
    echo "-t, --tag       push to a custom tag in your origin release image repo, default: latest"
    echo "-r, --release   openshift release version, default: 4.9"
    echo "-a, --auth      path of registry auth file, default: ./pull-secret.txt"
}

: ${TAG:="latest"}
: ${RELEASE:="4.9"}
: ${OC_REGISTRY_AUTH_FILE:="pull-secret.txt"}

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

echo "Building and uploading a custom image for KCMO"
./build_operator_image.sh -u "$USERNAME" -o cluster-kube-controller-manager-operator -i 536 -d Dockerfile.rhel7 -t "$TAG"

echo "Building and uploading a custom image for MCO"
./build_operator_image.sh -u "$USERNAME" -o machine-config-operator -i 2606 -t "$TAG"

echo "Building and uploading a custom image for CCCMO"
./build_operator_image.sh -u "$USERNAME" -o cluster-cloud-controller-manager-operator -i 73 -t "$TAG"

echo "Building a release image"
./build_release_image.sh -u "$USERNAME" -a "$OC_REGISTRY_AUTH_FILE" \
    --kcmo quay.io/mfedosin/cluster-kube-controller-manager-operator:"$TAG" \
    --mco quay.io/mfedosin/machine-config-operator:"$TAG" \
    --cccmo quay.io/mfedosin/cluster-kube-controller-manager-operator:"$TAG"