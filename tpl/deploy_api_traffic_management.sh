#!/usr/bin/env bash

export cluster=$1
export namespace=$2
if [[ $cluster == 'preview' ]]; then
  if [[ $namespace == 'di-dev' ]]; then
    host='dev.twdps.io'
  elif [[ $namespace == 'di-staging' ]]; then
    host='api.twdps.io'
  fi
fi

if [[ $cluster == 'sandbox' ]]; then
  if [[ $namespace == 'di-dev' ]]; then
    host="dev.$cluster.twdps.io"
  elif [[ $namespace == 'di-staging' ]]; then
    host="api.$cluster.twdps.io"
  fi
fi

cat <<EOF > api-traffic-management.yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: api-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "$host"
# ---
# apiVersion: networking.istio.io/v1alpha3
# kind: VirtualService
# metadata:
#   name: api-virtual-service
# spec:
#   hosts:
#   - "$host"
#   gateways:
#   - api-gateway
#   http:
#     - match:
#       - uri:
#           prefix: /teams
#       route:
#       - destination:
#           host: poc-va-api
#           port:
#             number: 5000
EOF
kubectl apply -f api-traffic-management.yaml -n $2

sleep 10
