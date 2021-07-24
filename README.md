<div align="center">
	<p>
		<img alt="Thoughtworks Logo" src="https://raw.githubusercontent.com/ThoughtWorks-DPS/static/master/thoughtworks_flamingo_wave.png?sanitize=true" width=200 />
    <br />
		<img alt="DPS Title" src="https://raw.githubusercontent.com/ThoughtWorks-DPS/static/master/dps_lab_title.png?sanitize=true" width=350/>
	</p>
  <h3>lab-platform-servicemesh</h3>
</div>
<br />

Starting point for istio servicemesh.

- Deploys Istio using istio operator with a manifest overlay
- - distroless images
- - json logging by default
- - tracing enabled
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

## Default namespaces and gateways

A common pattern for managing internal-customer tenanted namespaces and gateways is by default environment names.  

For example, company X provides access to apis via the api.example.com domain, and the default environments in the companies release pipelines are:  

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






add:  

- cert-manager (implementing acme for twdps.io)  
- standard env gateways (typically would support the Enterprise's default environments, later an operator is deployed to respond to customer self-management of add'l env)  



Adjust:

- currently the role assumed by the external-dns deploy is being created in the -eks pipeline, need to bring that into this repo and switch from tf to sdk configuration (since nothing else in this pipeline is tf)

