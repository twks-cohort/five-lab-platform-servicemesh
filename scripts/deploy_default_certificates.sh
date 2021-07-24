#!/usr/bin/env bash
set -e

export CLUSTER=${1}
export DOMAIN=$(cat ${CLUSTER}.cert-manager.json | jq -r '.domain')
export HOST=$CLUSTER.$DOMAIN

cat <<EOF >default-$CLUSTER-certificates.yaml
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${HOST}-certificate
  namespace: istio-system
spec:
  secretName: ${HOST}-certificate
  issuerRef:
    name: letsencrypt-$CLUSTER-issuer
    kind: ClusterIssuer
  commonName: "${HOST}"
  dnsNames:
  - "${HOST}"
  - "*.${HOST}"
EOF

kubectl apply -n istio-system -f default-$CLUSTER-certificates.yaml
