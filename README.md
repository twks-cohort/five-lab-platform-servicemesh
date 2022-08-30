<div align="center">
	<p>
		<img alt="Thoughtworks Logo" src="https://raw.githubusercontent.com/ThoughtWorks-DPS/static/master/thoughtworks_flamingo_wave.png?sanitize=true" width=200 />
    <br />
		<img alt="DPS Title" src="https://raw.githubusercontent.com/ThoughtWorks-DPS/static/master/EMPCPlatformStarterKitsImage.png?sanitize=true" width=350/>
	</p>
	<br />
	<a href="https://aws.amazon.com"><img src="https://img.shields.io/badge/-deployed-blank.svg?style=social&logo=amazon"></a>
	<br />
  <h3>lab-platform-servicemesh</h3>
	<a href="https://app.circleci.com/pipelines/github/ThoughtWorks-DPS/lab-platform-servicemesh"><img src="https://circleci.com/gh/ThoughtWorks-DPS/lab-platform-servicemesh.svg?style=shield"></a> <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
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
$ istioctl dashboard prometheus
$ istioctl dashboard grafana
$ istioctl dashboard jaeger
$ istioctl dashboard kiali   # use kiali token for respective cluster found in empc-lab op vault
```
## upgrades

Create a new revision config in the istio-configuration folder. Update the version in the install.json files and deploy. Note: this is presently an in-place upgrade that results in several seconds of service interruption.

## current deployment tests

**validate service status**

Confirms each of the deployed service containers is reporting a `Running` state.
```
validate_istio.bats
validate_external_dns.bats
validate_cert_manager.bats
validate_mesh_tools.bats
```

**validate basic mesh functionality**

Deploys an instance of httpbin to the lab-system-mtls namespace and defines a virtual service on the default cluster gateway for the twdps.io domain. This confirms the healthy functionality of the followins:
- the ingressgateway service successfully provisioned an ELB that includes EKS managed node instances.
- gateways were defined for the domains managed by the cluster
- certificates were successfully requested from LetsEncrypt and are attached to the gateways.
- envoy sidecars are successfully injected into managed namespaces
- istiod and the istio mutatingwebhook are successfully proxying traffic via envoy
- tls traffic successfully reaches the httpbin instance on https://httpbin.twdps.io

```
validate_ingress.sh
validate_twdps_io.bats
```
The httpbin testing service is deleted after a successful test.

### TODO:

- The external-dns deployment only supports a pre-defined list of env gateways. When the teams-api assumes the role of gateway management then the configuration deployed in this pipeline can reduce to only the cluster-name specific subdomain.
- convert istio install/upgrade to revision-based canary method.
