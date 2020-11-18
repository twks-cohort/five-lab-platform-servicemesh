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


# TODO

add:  

- external-dns  
- cert-manager (implementing acme for twdps.io)  
- standard env gateways (typically would support the Enterprise's default environments, later an operator is deployed to respond to customer self-management of add'l env)  



Adjust:

- currently the role assumed by the external-dns deploy is being created in the -eks pipeline, need to bring that into this repo and switch from tf to sdk configuration (since nothing else in this pipeline is tf)

