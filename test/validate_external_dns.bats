#!/usr/bin/env bats

@test "evaluate external-dns pod status" {
  run bash -c "kubectl get pods -n istio-system -o wide | grep 'external-dns'"
  [[ "${output}" =~ "Running" ]]
}
