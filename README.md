<div align="center">
	<p>
		<img alt="Thoughtworks Logo" src="https://raw.githubusercontent.com/ThoughtWorks-DPS/static/master/thoughtworks_flamingo_wave.png?sanitize=true" width=200 />
    <br />
		<img alt="DPS Title" src="https://raw.githubusercontent.com/ThoughtWorks-DPS/static/master/dps_lab_title.png?sanitize=true" width=350/>
	</p>
  <h3>lab-platform-servicemesh</h3>
</div>
<br />

The Lab servicemesh demonstrates the following configuration.  

- Deploys Istio using istio operator with a manifest overlay  
- - distroless images  
- - json logging by default  
- - tracing enabled  
- - ingressgateway enabled  
- Deploys external-dns for route53 automation  
- Deploys cert-manager with letsencrypt integration for automated ingress certificates  

**Domains**  

top level domain managed in same account: twdps.digital  
top level domain managed in different account: twdps.io   

## Default cluster gateways and namespaces

By default, cluster specific gateways and certificates exist for ingress by services and applications that are cluster-wide in nature (including test fixtures).   

CLUSTER-NAME.domain  
*.CLUSTER-NAME.domain  

A `default-mtls` namespace is deployed to each cluster for validate and testing of istio configurations.  

## to access istio UIs

```
$ istioctl dashboard controlz <pod-name[.namespace]>
$ istioctl dashboard envoy <pod-name[.namespace]>
```
## upgrades

Change the istio, external-dns, and cert-manager versions in the cluster.json.tpl and run the pipeline. Note: this will perform an in-place upgrade rather than a rolling update - expect some service interruption.  

### TODO:  
