#!/usr/bin/env bash
#
# parameters
# $1 = cluster config to use
export CLUSTER=${1}
export ISTIO_VERSION=$(cat environments/$CLUSTER.json | jq -r .istio_version)

# NOTE: this deploy process assumes in-place upgrades

# deploy operator matching installed istioctl version
istioctl operator init && sleep 10
kubectl apply -n istio-system -f manifests/istio-deploy-manifest-${ISTIO_VERSION}.yaml  && sleep 15


# quickstart versions - not tuned for production performance or security
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-${ISTIO_VERSION:0:3}/samples/addons/jaeger.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-${ISTIO_VERSION:0:3}/samples/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-${ISTIO_VERSION:0:3}/samples/addons/grafana.yaml

# kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.9/samples/addons/jaeger.yaml
# kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.9/samples/addons/prometheus.yaml
# kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.9/samples/addons/grafana.yaml

# This option installs the Kiali Operator and the Kiali CR for latest. It uses a non-default setting
# for accessible-namespaces making all current and future namespaces accessible to Kiali.
# This option is good for demo and development installations. This option grants special
# cluster role permissions and is not recommended for production.

kubectl create namespace kiali-operator
helm install --set cr.create=true --set cr.namespace=istio-system --namespace kiali-operator --repo https://kiali.org/helm-charts kiali-operator kiali-operator
sleep 20

kubectl get secrets -o json -n istio-system | jq -r '.items[] | select(.metadata.name | test("kiali-service-account")).data.token' > kiali-token
cat kiali-token | base64 --decode | secrethub write twdps/di/platform/env/$CLUSTER/cluster/kiali-token
