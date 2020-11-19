#!/usr/bin/env bats

@test "validate namespace status" {
  run bash -c "kubectl get namespaces -o wide | grep '$NAMESPACE'"
  [[ "${output}" =~ "Active" ]]
}