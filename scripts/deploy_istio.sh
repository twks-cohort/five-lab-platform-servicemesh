#!/usr/bin/env bash
set -e

# parameters
# $1 = cluster config to use
export CLUSTER=${1}
export ISTIO_VERSION=$(cat $CLUSTER.json | jq -r .istio_version)

# NOTE: this deploy process assumes in-place upgrades
istioctl install -y -f istio-manifests/istio-${ISTIO_VERSION}-manifest.yaml
sleep 15


# for running locally at fixed version
# kubectl apply -n istio-system -f istio-manifests/istio-deploy-manifest-1.10.0.yaml
# istio-1.13.0/bin/istioctl install -f istio-manifests/istio-1.13.0-manifest.yaml
