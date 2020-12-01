#!/usr/bin/env bash

export AWS_ACCOUNT_ID=$(secrethub read twdps/di/svc/aws/dps-2/aws-account-id )
export EMAIL=$(secrethub read twdps/di/svc/gmail/email)

aws sts assume-role --output json --role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/DPSTerraformRole --role-session-name deploy-external-dns-session >credentials
export AWS_ACCESS_KEY_ID=$(cat credentials | jq -r ".Credentials.AccessKeyId")
export AWS_SECRET_ACCESS_KEY=$(cat credentials | jq -r ".Credentials.SecretAccessKey")
export AWS_SESSION_TOKEN=$(cat credentials | jq -r ".Credentials.SessionToken")
export AWS_DEFAULT_REGION=us-east-2
export host=twdps.io

export HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name $host | jq -r --arg DNS $host '.HostedZones[] | select( .Name | startswith($DNS)) | .Id')

export cluster=$1
export environ=$2

if [[ $cluster == 'preview' ]]; then
  if [[ $environ == 'di-dev' ]]; then
    api_host="dev.twdps.io"
  elif [[ $environ == 'di-staging' ]]; then
    api_host="api.twdps.io"
  fi
fi

if [[ $cluster == 'sandbox' ]]; then
  if [[ $environ == 'di-dev' ]]; then
    api_host="dev.$cluster.twdps.io"
  elif [[ $environ == 'di-staging' ]]; then
    api_host="api.$cluster.twdps.io"
  fi
fi

create_dev_cert () {
  environ=$1
  api_host=$2

cat <<EOF >gateway-environment-cert-$environ.yaml
---
# Wildcard Certificate for Gateways specific to logical environment
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: $environ.twdps.di-cert
  namespace: istio-system
spec:
  secretName: $environ.twdps.di-cert
  issuerRef:
    name: letsencrypt-prod
    kind: Issuer
  dnsNames:
  - '$api_host'
  - '$environ.twdps.di'
  # acme:
  #   config:
  #   - dns01:
  #       provider: aws
  #     domains:
  #     - $api_host
EOF
}

create_prod_cert () {
  environ=$1
  api_host=$2

cat <<EOF >gateway-environment-cert-$environ.yaml
---
# Wildcard Certificate for Gateways specific to logical environment
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: $environ.twdps.di-cert
  namespace: istio-system
spec:
  secretName: $environ.twdps.di-cert
  issuerRef:
    name: letsencrypt-prod
    kind: Issuer
  dnsNames:
  - '$api_host'
  - 'twdps.di'
  - 'www.twdps.di'
EOF
}

cat <<EOF >certificate_configuration.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: twdps.io-${1}
spec:
  acme:
    email: $EMAIL
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: twdps.io-${1}-secret
    solvers:
    - selector:
        dnsZones:
          - "twdps.io"
      dns01:
        route53:
          region: $AWS_DEFAULT_REGION
          hostedZoneID: $HOSTED_ZONE_ID # optional, see policy above
          role: arn:aws:iam::${AWS_ACCOUNT_ID}:role/${1}-external-dns
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: twdps.io-certificate
  namespace: cert-manager
spec:
  secretName: twdps.io-certificate-secret
  issuerRef:
    name: twdps.io-${1}
    kind: ClusterIssuer
  dnsNames:
  - '*.twdps.io'
  - twdps.io
EOF

kubectl apply -f certificate_configuration.yaml

## Gateway certs

cat <<EOF >gateway-cert-$cluster.yaml 
---
# Wildcard Certificate for default Gateways
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: star.$cluster
  namespace: istio-system
spec:
  secretName: star.$cluster-cert
  issuerRef:
    name: letsencrypt-prod
    kind: Issuer
  dnsNames:
  - '*.$host'
  # acme:
  #   config:
  #   - dns01:
  #       provider: aws   # this piece may look different depending on aws integration method
  #     domains:
  #     - twdps.io
EOF

kubectl apply -f gateway-cert-$cluster.yaml


# And then each cluster will have a number of ENVIRONMENT gateways deployed and certicates. 
#  In the POC we said we would just have two (dev, staging) with staging representing Production
#   - but for the example below, it includes the differences that will be needed for an actual prod.

# anyone publishing a virtualservice from any namespace (whether this team or our customers), 
# then decides which ingress they want to use and the associated environ gateway.

# certificate per environment

if [[ $environ == 'di-staging' ]]; then
  echo "Di-STAGING"
  create_prod_cert $environ $api_host
else
  echo "DI-DEV"
  create_dev_cert $environ $api_host
fi 

kubectl apply -f gateway-environment-cert-$environ.yaml

sleep 10
