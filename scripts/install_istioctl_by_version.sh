#!/usr/bin/env bash

export CLUSTER=${1}
export ISTIO_VERSION=$(cat $CLUSTER.json | jq -r .istio_version)

curl -L https://istio.io/downloadIstio  | ISTIO_VERSION="${ISTIO_VERSION}" sh -
sudo mv "istio-${ISTIO_VERSION}/bin/istioctl" /usr/local/bin/istioctl
sudo rm -rf "istio-${ISTIO_VERSION}"
