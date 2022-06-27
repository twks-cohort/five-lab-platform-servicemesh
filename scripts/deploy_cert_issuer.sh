#!/usr/bin/env bash
set -e

export CLUSTER=$1
export AWS_DEFAULT_REGION=$(cat $CLUSTER.auto.tfvars.json | jq -r .aws_region)
export AWS_ACCOUNT_ID=$(cat $CLUSTER.auto.tfvars.json | jq -r .aws_account_id)

kubectl apply -f ${CLUSTER}-cluster-issuer.yaml
