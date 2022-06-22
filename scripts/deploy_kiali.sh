#!/usr/bin/env bash
#
# parameters
# $1 = cluster config to use
export CLUSTER=${1}
export KIALI_VERSION=$(cat environments/$CLUSTER.install.json | jq -r .kiali_version)

# This option installs the Kiali Operator and the Kiali CR for latest. It uses a non-default setting
# for accessible-namespaces making all current and future namespaces accessible to Kiali.
# This option is good for demo and development installations. This option grants special
# cluster role permissions and is not recommended for production.

kubectl apply -f tpl/kiali-namespace.yaml
helm upgrade --install --version $KIALI_VERSION --set cr.create=true --set cr.namespace=istio-system --namespace kiali-operator --repo https://kiali.org/helm-charts kiali-operator kiali-operator
sleep 40

kubectl get secrets -o json -n istio-system | jq -r '.items[] | select(.metadata.name | test("kiali-service-account")).data.token' > kiali-token
cat kiali-token | base64 -d | opw write platform-$CLUSTER kiali-token -
