#!/usr/bin/env bash
#
# parameters
# $1 = cluster config to use

export ISTIO_VERSION=$(cat tpl/${1}.json | jq -r '.istio_version')
export KIALI_VERSION=$(cat tpl/${1}.json | jq -r '.kiali_version')
export DEFAULT_LIMITS_CPU=$(cat tpl/${1}.json | jq -r '.default_limits_cpu')
export DEFAULT_LIMITS_MEMORY=$(cat tpl/${1}.json | jq -r '.default_limits_memory')

curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -

kubectl apply -f istio-namespace.yaml
istioctl install -f istio-deploy-overlay.yaml

# quickstart versions - not tuned for production performance or security
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.7/samples/addons/jaeger.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.7/samples/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.7/samples/addons/grafana.yaml
kubectl apply -f kiali-deployment.yaml

sleep 10
