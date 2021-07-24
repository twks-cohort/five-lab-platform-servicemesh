#!/usr/bin/env bash
set -e

export CLUSTER=$1

cat <<EOF > default-$CLUSTER-gateways.yaml
---
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: $CLUSTER-gateway
  namespace: istio-system
  labels:
    istio: istio-ingressgateway
spec:
  selector:
    app: istio-ingressgateway
  servers:
  - port:
      number: 80
      name: http-$CLUSTER
      protocol: HTTP
    hosts:
    - "$CLUSTER.twdps.io"
    - "*.$CLUSTER.twdps.io"
    tls:
      httpsRedirect: true # sends 301 redirect for http requests
  - port:
      number: 443
      name: https-$CLUSTER
      protocol: HTTPS
    hosts:
    - "$CLUSTER.twdps.io"
    - "*.$CLUSTER.twdps.io"
    tls:
      mode: SIMPLE 
      credentialName: $CLUSTER.twdps.io-certificate
EOF

kubectl apply -f default-$CLUSTER-gateways.yaml

if [[ $CLUSTER == "preview" ]]; then
  kubectl apply -f tpl/preview-gateways.yaml
fi
