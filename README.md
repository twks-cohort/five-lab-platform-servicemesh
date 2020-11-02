# lab-platform-servicemesh

NOTE: not yet tested on twdps aws account


Starting point for istio servicemesh.

- Deploys Istio using istioctl deploy with manifest overlay
- - distroless images
- - meshConfig.accessLogFile: "/dev/stdout"
- - meshConfig.accessLogEncoding: "JSON" 
- - ingressgateway enabled
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
