#!/bin/bash

help() {
    echo "Build an operator image with custom changes to support external cloud providers"
    echo ""
    echo "Usage: ./build_operator_image.sh [options]"
    echo "Options:"
    echo "-h, --help      show this message"
    echo "-o, --operator  operator name to build, available options: mco, kapio, kcmo"
    echo "-u, --username  registered username in quay.io"
    echo "-t, --tag       push to a custom tag in your origin release image repo, default: latest"
    echo ""
}

TAG="latest"

# Parse Options
case $1 in
    -h|--help)
        help
        exit 0;;
    -t|--tag)
        TAG=$2
        shift
        shift;;
    -u|--username)
        USERNAME=$2
        shift 2
        ;;
    -o|--operator)
        OPERATOR=$2
        shift 2
        ;;
    *);;
esac

if [ -z "$USERNAME" ]; then
    echo "No quay.io username provided, exiting ..."
    exit 1
fi

if [ -z "$OPERATOR" ]; then
    echo "No operator name provided, exiting ..."
    exit 1
fi

case $OPERATOR in

  mco)
    OPERATOR_IMAGE=quay.io/$USERNAME/machine-config-operator:$TAG
    ;;

  kapio)
    OPERATOR_IMAGE=quay.io/$USERNAME/cluster-kube-apiserver-operator:$TAG
    ;;

  kcmo)
    OPERATOR_IMAGE=quay.io/$USERNAME/cluster-kube-controller-manager-operator:$TAG
    ;;

  *)
    echo -n "unknown operator image name"
    exit 1
    ;;
esac

echo "Setting operator image to $OPERATOR_IMAGE"

set -ex

echo "Start building operator image"
podman build --no-cache -t $OPERATOR_IMAGE -f Dockerfile.$OPERATOR

echo "Pushing operator image to quay.io"
podman push $OPERATOR_IMAGE

echo "Successfully pushed $OPERATOR_IMAGE"
