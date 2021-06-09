#!/bin/bash

help() {
    echo "Build an MCO Image"
    echo ""
    echo "Usage: ./build_mco.sh [options] <quay.io username>"
    echo "Options:"
    echo "-h, --help      show this message"
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
    *);;
esac

if [ -z "$1" ]; then
    echo "No quay.io username provided, exiting ..."
    exit 1
fi

set -ex

USERNAME="$1"

MCO_IMAGE=quay.io/$USERNAME/machine-config-operator:$TAG

podman build --no-cache -t $MCO_IMAGE -f Dockerfile.mco
podman push $MCO_IMAGE
