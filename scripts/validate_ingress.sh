#!/usr/bin/env bash
set -e

export CLUSTER=$1
export SAME_ACCOUNT_DOMAIN=$(cat $CLUSTER.json | jq -r '.same_account_domain')
export CROSS_ACCOUNT_DOMAIN=$(cat $CLUSTER.json | jq -r '.cross_account_domain')

# deploy and test httpbin on same account domain
bash scripts/deploy_httpbin.sh ${CLUSTER} ${SAME_ACCOUNT_DOMAIN}

# this is a complete hack - need to sort out params to bats tests
if [[ $CLUSTER == "sandbox" ]]; then
  bats test/validate_sandbox_twdps_digital.bats
elif [[ $CLUSTER == "preview" ]]; then
  bats test/validate_preview_twdps_digital.bats
fi

# deploy and test httpbin on cross account domain
bash scripts/deploy_httpbin.sh ${CLUSTER} ${CROSS_ACCOUNT_DOMAIN}

# this is a complete hack - need to sort out params to bats tests
if [[ $CLUSTER == "sandbox" ]]; then
  bats test/validate_sandbox_twdps_io.bats
elif [[ $CLUSTER == "preview" ]]; then
  bats test/validate_preview_twdps_io.bats
fi

kubectl delete -f httpbin.$CLUSTER.$CROSS_ACCOUNT_DOMAIN.yaml
