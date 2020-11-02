#!/usr/bin/env bash
#
# parameters
# $1 = cluster config to use

export CERT_MANAGER_VERSION=$(cat tpl/${1}.json | jq -r '.cert_manager_version')

kubectl apply -f cert-manager-namespace.yaml
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v${CERT_MANAGER_VERSION}/cert-manager.yaml

kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v${CERT_MANAGER_VERSION}/cert-manager.crds.yaml

https://github.com/jetstack/cert-manager/releases/download/v1.0.3/cert-manager.yaml
