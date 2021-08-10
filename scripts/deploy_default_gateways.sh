#!/usr/bin/env bash
set -e

export CLUSTER=$1
export SAME_ACCOUNT_DOMAIN=$(cat $CLUSTER.json | jq -r '.same_account_domain')
export CROSS_ACCOUNT_DOMAIN=$(cat $CLUSTER.json | jq -r '.cross_account_domain')

cat <<EOF > default-$CLUSTER-certificates.yaml
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${CLUSTER}-digital-wildcard-certificate
  namespace: istio-system
spec:
  secretName: ${CLUSTER}-digital-wildcard-certificate
  issuerRef:
    name: "letsencrypt-${CLUSTER}-issuer"
    kind: ClusterIssuer
  commonName: "*.${CLUSTER}.${SAME_ACCOUNT_DOMAIN}"
  dnsNames:
  - "${CLUSTER}.${SAME_ACCOUNT_DOMAIN}"
  - "*.${CLUSTER}.${SAME_ACCOUNT_DOMAIN}"

---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${CLUSTER}-io-wildcard-certificate
  namespace: istio-system
spec:
  secretName: ${CLUSTER}-io-wildcard-certificate
  issuerRef:
    name: "letsencrypt-${CLUSTER}-issuer"
    kind: ClusterIssuer
  commonName: "*.${CLUSTER}.${CROSS_ACCOUNT_DOMAIN}"
  dnsNames:
  - "${CLUSTER}.${CROSS_ACCOUNT_DOMAIN}"
  - "*.${CLUSTER}.${CROSS_ACCOUNT_DOMAIN}"

EOF

kubectl apply -f default-$CLUSTER-certificates.yaml

cat <<EOF > default-$CLUSTER-gateways.yaml
---
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: $CLUSTER-wildcard-gateway
  namespace: istio-system
  labels:
    istio: istio-ingressgateway
spec:
  selector:
    app: istio-ingressgateway
  servers:
  # - port:
  #     number: 80
  #     name: http-sandbox
  #     protocol: HTTP
  #   hosts:
  #   - "*.${CLUSTER}.${SAME_ACCOUNT_DOMAIN}"
  #   - "${CLUSTER}.${SAME_ACCOUNT_DOMAIN}"
  # #   tls:
  # #     httpsRedirect: true # sends 301 redirect for http requests
  - port:
      number: 443
      name: https-$CLUSTER-digital
      protocol: HTTPS
    hosts:
    - "${CLUSTER}.${SAME_ACCOUNT_DOMAIN}"
    - "*.${CLUSTER}.${SAME_ACCOUNT_DOMAIN}"
    tls:
      mode: SIMPLE 
      credentialName: $CLUSTER-digital-wildcard-certificate
  - port:
      number: 443
      name: https-$CLUSTER-io
      protocol: HTTPS
    hosts:
    - "${CLUSTER}.${CROSS_ACCOUNT_DOMAIN}"
    - "*.${CLUSTER}.${CROSS_ACCOUNT_DOMAIN}"
    tls:
      mode: SIMPLE 
      credentialName: $CLUSTER-io-wildcard-certificate
EOF

kubectl apply -f default-$CLUSTER-gateways.yaml
