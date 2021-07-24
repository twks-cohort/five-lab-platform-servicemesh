#!/usr/bin/env bats

@test "evaluate istio ingressgateway service status" {
  run bash -c "kubectl get svc -n istio-system"
  [[ "${output}" =~ "istio-ingressgateway" ]]
  [[ "${output}" =~ "LoadBalancer" ]]
}

@test "evaluate istio ingressgateway pod status" {
  run bash -c "kubectl get pods -n istio-system -o wide | grep 'istio-ingressgateway'"
  [[ "${output}" =~ "Running" ]]
}

@test "evaluate istio istiod pod status" {
  run bash -c "kubectl get pods -n istio-system -o wide | grep 'istiod'"
  [[ "${output}" =~ "Running" ]]
}
