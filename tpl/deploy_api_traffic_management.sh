#!/usr/bin/env bash

export cluster=$1
export environ=$2
if [[ $cluster == 'preview' ]]; then
  if [[ $environ == 'di-dev' ]]; then
    host='dev.twdps.io'
  elif [[ $environ == 'di-staging' ]]; then
    host='api.twdps.io'
  fi
fi

if [[ $cluster == 'sandbox' ]]; then
  if [[ $environ == 'di-dev' ]]; then
    host="dev.$cluster.twdps.io"
  elif [[ $environ == 'di-staging' ]]; then
    host="api.$cluster.twdps.io"
  fi
fi

# star cert for default gateways


# each cluster will have default gateways for each of the ingressgateways
# gateway_source = [ internal | external | external-whitelist ]

for GATEWAY_SOURCE in internal external external-whitelist
do
cat <<EOF > gateway-default-$GATEWAY_SOURCE.yaml
---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: $GATEWAY_SOURCE-gateway
  namespace: istio-system
  labels:
    app: istio-ingressgateway
    istio: $GATEWAY_SOURCE-ingressgateway
spec:
  selector:
    istio: $GATEWAY_SOURCE-ingressgateway
  servers:
  - port:
      number: 443
      name: https-$GATEWAY_SOURCE
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: star.$cluster-cert
    hosts:
    - '*'
EOF
# kubectl apply -f gateway-default-$GATEWAY_SOURCE.yaml
done 



# 
for GATEWAY_SOURCE in internal external external-whitelist
do
cat <<EOF > gateway-$environ-$GATEWAY_SOURCE.yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: $GATEWAY_SOURCE-$environ-gateway
  namespace: istio-system
spec:
  selector:
    istio: $GATEWAY_SOURCE-ingressgateway
  servers:
  - port:
      number: 443
      name: https-api-$environ-twdps.di-name
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: $environ.twdps.di-cert
    hosts:
      - "$host"

EOF
# kubectl apply -f gateway-$environ-$GATEWAY_SOURCE.yaml
done 


