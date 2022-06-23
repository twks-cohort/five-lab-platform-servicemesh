#!/usr/bin/env bash
set -e

export CLUSTER=$1

# deploy and test httpbin on same account domain
bash scripts/deploy_httpbin.sh ${CLUSTER}
sleep 10

bats test/validate_twdps_io.bats

#kubectl delete -f httpbin-twdps-io-gateway.yaml