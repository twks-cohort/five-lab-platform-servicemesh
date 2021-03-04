#!/usr/bin/env bash
set -e

# export API_GATEWAY=$(cat tpl/${1}.json | jq -r ".api_gateway_subdomains.${2}")
# export HOST=$(cat tpl/${1}.json | jq -r '.host')
export CLUSTER=${1}
export DOMAIN=$(cat tpl/${CLUSTER}.json | jq -r '.domain')

cat <<EOF > environment-gateways.yaml
---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: api-dev-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "api.dev.$DOMAIN"

---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: api-qa-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "api.qa.$DOMAIN"
EOF
kubectl apply -f environment-gateways.yaml

sleep 10
