
_nonprod cluster_  
dev  
qa  
staging  

_prod cluster_  
prod  

Company X has three teams working:  
blue  
red  
green  

| cluster  | blue team    | red team    | green team    | gateway         |
|----------|--------------|-------------|---------------|-----------------|
| non-prod | blue-dev     | red-dev     | green-dev     | dev-gateway     |
| non-prod | blue-qa      | red-qa      | green-qa      | qa-gateway      |
| non-prod | blue-staging | red-staging | green-staging | staging-gateway |
| prod     | blue-prod    | red-prod    | green-prod    | prod-gateway    |


| gateway         | url                                   |
|-----------------|---------------------------------------|
| dev-gateway     | dev.api.example.com/team-api-name     |
| qa-gateway      | qa.api.example.com/team-api-name      |
| staging-gateway | staging.api.example.com/team-api-name |
| prod-gateway    | api.example.com/team-api-name         |




- - prometheus, grafana, jaeger, kiali have quickstart installs, not production ready, only proxy access

## to access UIs

```
$ istioctl dashboard controlz <pod-name[.namespace]>
$ istioctl dashboard envoy <pod-name[.namespace]>
$ istioctl dashboard prometheus
$ istioctl dashboard grafana
$ istioctl dashboard jaeger
$ istioctl dashboard kiali
```


  deploy-istio-integrations:
      parameters:
        cluster:
          description: target kubernetes cluster
          type: string
          default: ""
      steps:
        - run:
            name: deploy quickstart prometheus matching istio version
            command: bash scripts/deploy_prometheus.sh << parameters.cluster >>
        - run:
            name: deploy quickstart grafana matching istio version
            command: bash scripts/deploy_grafana.sh << parameters.cluster >>
        - run:
            name: deploy quickstart jaeger matching istio version
            command: bash scripts/deploy_jaeger.sh << parameters.cluster >>
        - run:
            name: deploy current release version of kiali
            command: bash scripts/deploy_kiali.sh << parameters.cluster >>
        - run:
            name: validate istio deployment
            command: CLUSTER=<< parameters.cluster >> bats test/validate_istio_integrations.bats


#!/usr/bin/env bats

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
