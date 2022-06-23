#!/usr/bin/env bash
set -e

# parameters
# $1 = type of change to make [revision | swap | drop]
#      revision: deploy a prod-canary revision of .istio_version
#      swap: swap the live version of istio from prod-stable to prod-canary
#      drop: uninstall the prod-canary revision
#      inplace: just do in-place install and upgrade
# $2 = cluster config to use

export CLUSTER=${1}
export CHANGE=${2}
export REVISION_VERSION=$(cat environments/$CLUSTER.install.json | jq -r .istio_version)
export REVISION_LABEL=$(echo "${REVISION_VERSION}" | sed -r 's/[.]+/-/g')


# deploy a revision
function revision_deploy() {
  echo "revision deployment of istio version $REVISION_VERSION"
  istio-${REVISION_VERSION}/bin/istioctl install -y --set revision=$REVISION_LABEL -f istio-configuration/set-istio-${REVISION_VERSION}.yaml
}

# tag revisions
function revision_tag() {
  if [[ $1 == "prod-stable" ]]; then
    echo "tag $REVISION_LABEL as prod-stable"
    istio-${REVISION_VERSION}/bin/istioctl tag set prod-stable --revision $REVISION_LABEL
    istio-${REVISION_VERSION}/bin/istioctl tag set default --revision $REVISION_LABEL
  elif [[ $1 == "canary" ]]; then
    echo "tag $REVISION_LABEL as canary"
    istio-${REVISION_VERSION}/bin/istioctl tag set prod-canary --revision $REVISION_LABEL
  fi
}

# install specified istio version
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$REVISION_VERSION sh -
istio-${REVISION_VERSION}/bin/istioctl version --short --remote=false || { echo "error: invalid istioctl version"; exit 2; }

# deploy a new revision
if [[ $CHANGE == "revision" ]]; then


  # if istio is not found already on the cluster, then do an initial default/prod-stable revision deployment
  if ! kubectl get pods -n istio-system | grep istio-ingressgateway; then
    echo "istio not found on cluster, deploying default/prod-stable revision based on .istio_version"
    revision_deploy $ISTIO_VERSION
    revision_tag prod-stable
  fi

  # fetch current istio revision
  export CURRENT_REVISION=$(istio-${REVISION_VERSION}/bin/istioctl tag get default --remote=false)

  # if the current prod-stable revision is equal to the .istio_version then do nothing, warn
  if [[ $CURRENT_REVISION == $REVISION_VERSION ]]; then
    echo "the current prod-stable revision is already the same as the .istio_version, nothing to do"
    exit 1
  fi

  revision_deploy $ISTIO_VERSION
  revision_tag canary

# swap istio from prod-stable to prod-canary
elif [[ $CHANGE == "swap" ]]; then

  echo "swap"
  # if the prod-stable revision is equal to the $REVISION_LABEL revision then do nothing, warn

  # swap
  # PRIOR_VERSION = current prod-stable revision

  # send event message to global channel to indicate customers should bounce

# remove the canary revision
elif [[ $CHANGE == "drop" ]]; then

  echo "drop"
  # if there is to prod-canary revision then do nothing, warn

  # CANARY_VERSION = fetch prob-canary revision
  # istioctl x uninstall --revision=$CANARY_VERSION 
elif [[ $CHANGE == "inplace" ]]; then

  # if istio is not found already on the cluster, then do an initial install
  if ! kubectl get pods -n istio-system | grep istio-ingressgateway; then
    echo "istio not found on cluster, deploying in-place based on .istio_version"
    istio-${REVISION_VERSION}/bin/istioctl install -y -f istio-configuration/set-istio-${REVISION_VERSION}.yaml
  fi

  # upgrade - will be a second idempotent run in the case of the initial install on a new cluster
  istio-${REVISION_VERSION}/bin/istioctl upgrade -y -f istio-configuration/set-istio-${REVISION_VERSION}.yaml

fi
