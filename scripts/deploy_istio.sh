#!/usr/bin/env bash
#
# parameters
# $1 = cluster config to use
export CLUSTER=${1}
export ISTIO_VERSION=$(cat $CLUSTER.json | jq -r .istio_version)

# NOTE: this deploy process assumes in-place upgrades

# deploy operator matching installed istioctl version
istioctl operator init && sleep 10
kubectl apply -n istio-system -f istio-manifests/istio-deploy-manifest-${ISTIO_VERSION}.yaml  && sleep 15


# for running locally
# kubectl apply -n istio-system -f istio-manifests/istio-deploy-manifest-1.10.0.yaml
# istio-1.10.0/bin/istioctl operator init
