#!/usr/bin/env bats

@test "evaluate api gateway existence" {
  run bash -c "kubectl get gateway -n istio-system -o wide"
  [[ "${output}" =~ "monitoring-gateway" ]]

}

@test "evaluate api virtual service existence for dev" {
  run bash -c "kubectl get virtualservice -n istio-system | grep 'kiali-virtual-service'"
  if [[ $CLUSTER == 'sandbox' ]]; then
    [[ "${output}" =~ "["istio-system.sandbox.twdps.io"]" ]]
  elif [[ $CLUSTER == 'preview' ]]; then
    [[ "${output}" =~ "["istio-system.twdps.io"]" ]]
  fi
}
