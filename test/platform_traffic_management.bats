#!/usr/bin/env bats

@test "evaluate api gateway existence" {
  run bash -c "kubectl get gateway -n di-dev -o wide"
  [[ "${output}" =~ "api-gateway" ]]

  run bash -c "kubectl get gateway -n di-staging -o wide"
  [[ "${output}" =~ "api-gateway" ]]
}
