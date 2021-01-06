#!/usr/bin/env bash

export cluster=$1
export environ=$2
#!/usr/bin/env bash
set -e

export API_GATEWAY=$(cat tpl/$cluster.json | jq -r ".api_gateway_subdomains.$environ")
export HOST=$(cat tpl/$cluster.json | jq -r '.host')

cat <<EOF > api-traffic-management.yaml
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${HOST}-$environ-certificate
  namespace: istio-system
spec:
  secretName: ${HOST}-$environ-certificate
  issuerRef:
    name: ${HOST}-issuer
    kind: ClusterIssuer
  commonName: "$API_GATEWAY"
  dnsNames:
  - "$API_GATEWAY"
---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: api-gateway-$environ
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    tls:
      httpsRedirect: true
    hosts:
    - "$API_GATEWAY"
EOF
#kubectl apply -f api-traffic-management.yaml

sleep 10
