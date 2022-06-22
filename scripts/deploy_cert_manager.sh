#!/usr/bin/env bash
set -e

export CLUSTER=${1}
export AWS_ACCOUNT_ID=$(cat ${CLUSTER}.auto.tfvars.json | jq -r .aws_account_id)
export CERT_MANAGER_VERSION=$(cat environments/${CLUSTER}.install.json | jq -r '.cert_manager_chart_version')


kubectl apply -f tpl/cert-manager-namespace.yaml

helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --wait -i cert-manager jetstack/cert-manager --namespace cert-manager --version v${CERT_MANAGER_VERSION} --set installCRDs=true --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::${AWS_ACCOUNT_ID}:role/${CLUSTER}-cert-manager --set securityContext.enabled=true --set securityContext.fsGroup=1001
sleep 15
