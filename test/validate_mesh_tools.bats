#!/usr/bin/env bats

@test "evaluate istio-prometheus pod status" {
  run bash -c "kubectl get pods -n istio-system -o wide | grep 'prometheus'"
  [[ "${output}" =~ "Running" ]]
}

@test "evaluate istio-grafana pod status" {
  run bash -c "kubectl get pods -n istio-system -o wide | grep 'grafana'"
  [[ "${output}" =~ "Running" ]]
}

@test "evaluate jaeger pod status" {
  run bash -c "kubectl get pods -n istio-system -o wide | grep 'jaeger'"
  [[ "${output}" =~ "Running" ]]
}
