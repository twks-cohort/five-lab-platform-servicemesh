#!/usr/bin/env bash
set -e

export CLUSTER=$1
export SAME_ACCOUNT_DOMAIN=$(cat $CLUSTER.json | jq -r '.same_account_domain')
export CROSS_ACCOUNT_DOMAIN=$(cat $CLUSTER.json | jq -r '.cross_account_domain')

# deploy and test httpbin on same account domain
bash scripts/deploy_httpbin.sh ${CLUSTER} ${SAME_ACCOUNT_DOMAIN}
bats test/validate_twdps_digital.bats

# deploy and test httpbin on cross account domain
bash scripts/deploy_httpbin.sh ${CLUSTER} ${CROSS_ACCOUNT_DOMAIN}
bats test/validate_twdps_io.bats

kubectl delete -f httpbin.$CLUSTER.$CROSS_ACCOUNT_DOMAIN.yaml
