#!/usr/bin/env bats

@test "evaluate istio ingressgateway service status" {
  run bash -c "kubectl get svc -n istio-system"
  [[ "${output}" =~ "istio-ingressgateway" ]]
  [[ "${output}" =~ "LoadBalancer" ]]
  [[ "${output}" =~ "us-west-2.elb.amazonaws.com" ]]
}

@test "evaluate external-dns status" {
  run bash -c "kubectl get po -n kube-system -o wide | grep 'external-dns'"
  [[ "${output}" =~ "Running" ]]
}

@test "evaluate istio ingressgateway pod status" {
  run bash -c "kubectl get pods -n istio-system -o wide | grep 'istio-ingressgateway'"
  [[ "${output}" =~ "Running" ]]
}

@test "evaluate istio istiod pod status" {
  run bash -c "kubectl get pods -n istio-system -o wide | grep 'istiod'"
  [[ "${output}" =~ "Running" ]]
}

@test "evaluate grafana pod status" {
  run bash -c "kubectl get pods -n istio-system -o wide | grep 'grafana'"
  [[ "${output}" =~ "Running" ]]
}

@test "evaluate prometheus pod status" {
  run bash -c "kubectl get pods -n istio-system -o wide | grep 'prometheus'"
  [[ "${output}" =~ "Running" ]]
}

@test "evaluate jaeger pod status" {
  run bash -c "kubectl get pods -n istio-system -o wide | grep 'jaeger'"
  [[ "${output}" =~ "Running" ]]
}

@test "evaluate kiali pod status" {
  run bash -c "kubectl get pods -n istio-system -o wide | grep 'kiali'"
  [[ "${output}" =~ "Running" ]]
}
