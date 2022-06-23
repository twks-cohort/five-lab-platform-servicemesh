<div align="center">
	<p>
		<img alt="Thoughtworks Logo" src="https://raw.githubusercontent.com/ThoughtWorks-DPS/static/master/thoughtworks_flamingo_wave.png?sanitize=true" width=200 />
    <br />
		<img alt="DPS Title" src="https://raw.githubusercontent.com/ThoughtWorks-DPS/static/master/dps_lab_title.png?sanitize=true" width=350/>
	</p>
	<br />
	<a href="https://aws.amazon.com"><img src="https://img.shields.io/badge/-deployed-blank.svg?style=social&logo=amazon"></a>
	<br />
  <h3>lab-platform-servicemesh</h3>
</div>
<br />

The Lab servicemesh demonstrates the following configuration.  

- Deploys Istio using `istioctl install` with parameters file
- - Uses canary upgrade deployment method. If istio has not yet been deployed to the cluster, it will do a default/prod revision install of the same version.
- - distroless images  
- - json logging by default  
- - tracing enabled  
- - ingressgateway enabled  
- Deploys external-dns for route53 automation  
- Deploys cert-manager with letsencrypt integration for automated ingress certificates  

**gateways**  

### gateways

The following gateways are currently deployed by this pipeline. 

Default cluster gateways:  

| gateway                                 | urls                                |  cluster          |
|-----------------------------------------|-------------------------------------|-------------------|
| dev.twdps.digital-gateway               | (*.)dev.twdps.digital               | prod-us-east-1    |
| dev.twdps.io-gateway                    | (*.)dev.twdps.io                    | prod-us-east-1    |
| qa.twdps.digital-gateway                | (*.)qa.twdps.digital                | prod-us-east-1    |
| qa.twdps.io-gateway                     | (*.)qa.twdps.io                     | prod-us-east-1    |
| preview.twdps.digital-gateway           | (*.)preview.twdps.digital           | sandbox-us-east-2 |
| preview.twdps.io-gateway                | (*.)preview.twdps.io                | sandbox-us-east-2 |
| prod.twdps.digital-gateway              | (*.)prod.twdps.digital              | prod-us-east-1    |
| prod.twdps.io-gateway                   | (*.)prod.twdps.io                   | prod-us-east-1    |
| twdps.io-gateway                        | (*.)twdps.io                        | prod-us-east-1    |
| twdps.digital-gateway                   | (*.)twdps.digital                   | sandbox-us-east-2 |

Namespace environment gateways:  

| gateway                                 | urls                                |  cluster          |
|-----------------------------------------|-------------------------------------|-------------------|
| sandbox-us-east-2.twdps.digital-gateway | (*.)sandbox-us-east-2.twdps.digital | sandbox-us-east-2 |
| sandbox-us-east-2.twdps.io-gateway      | (*.)sandbox-us-east-2.twdps.io      | sandbox-us-east-2 |
| prod-us-east-1.twdps.digital-gateway    | (*.)prod-us-east-1.twdps.digital    | prod-us-east-1    |
| prod-us-east-1.twdps.io-gateway         | (*.)prod-us-east-1.twdps.io         | prod-us-east-1    |

A typical external->internal routing patterns for domains would be:  

api.twdps.io      >  api-gateway  >  api.prod.preview.twdps.io  

Note: the pending teams.api release will shift management of standard environment gateways to the api rather than through an infra pipeline.    

## Default namespace

A `default-mtls` namespace is deployed to each cluster for validate and testing of istio configurations.  

## to access istio UIs

```
$ istioctl dashboard controlz <pod-name[.namespace]>
$ istioctl dashboard envoy <pod-name[.namespace]>
```
## upgrades

Create a new revision config in the istio-configuration folder. Update the version in the install.json files and deploy. Note: this is presently an in-place upgrade that results in several seconds of service interruption.

### TODO:  

- The external-dns deployment only supports a pre-defined list of env gateways. When the teams-api assumes the role of gateway management then the configuration deployed in this pipeline can reduce to only the clsuter-name specific subdomain.  
- convert to revision-based canary upgrades.  