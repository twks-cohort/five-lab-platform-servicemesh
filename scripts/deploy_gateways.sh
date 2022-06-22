#!/usr/bin/env bash
set -e

export CLUSTER=$1
export CLUSTER_DOMAINS=$(cat environments/$CLUSTER.install.json | jq -r .cluster_domains)

declare -a domains=($(echo $CLUSTER_DOMAINS | jq -r '.[]'))

for domain in "${domains[@]}";
do

  cat <<EOF > $domain-certificate.yaml
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: $domain-certificate
  namespace: istio-system
spec:
  secretName: $domain-certificate
  issuerRef:
    name: "letsencrypt-${CLUSTER}-issuer"
    kind: ClusterIssuer
  commonName: "*.$domain"
  dnsNames:
  - "$domain"
  - "*.$domain"
EOF
kubectl apply -f $domain-certificate.yaml

export gateway=$( echo $domain | tr . - )
  cat <<EOF > $domain-gateway.yaml
---
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: $gateway-gateway
  namespace: istio-system
  labels:
    istio: istio-ingressgateway
spec:
  selector:
    app: istio-ingressgateway
  servers:
  - port:
      number: 80
      name: http-$domain
      protocol: HTTP
    hosts:
    - "$domain"
    - "*.$domain"
    tls:
      httpsRedirect: true 
  - port:
      number: 443
      name: https-$domain
      protocol: HTTPS
    hosts:
    - "$domain"
    - "*.$domain"
    tls:
      mode: SIMPLE 
      credentialName: "$domain-certificate"
EOF
kubectl apply -f $domain-gateway.yaml

done

