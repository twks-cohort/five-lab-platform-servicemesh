#!/usr/bin/env bats

@test "evaluate api gateway existence" {
  run bash -c "kubectl get gateway -n istio-system -o wide"
  [[ "${output}" =~ "api-gateway" ]]

  run bash -c "kubectl get gateway -n istio-system -o wide"
  [[ "${output}" =~ "api-gateway" ]]
}
