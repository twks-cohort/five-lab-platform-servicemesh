#!/usr/bin/env bash

export AWS_ACCOUNT_ID=$(secrethub read twdps/di/svc/aws/dps-2/aws-account-id )
export CM_AWS_ACCESS_KEY_ID=$(secrethub read twdps/di/svc/aws/dps-2/DPSSimpleServiceAccount/aws-access-key-id)
export CM_AWS_SECRET_ACCESS_KEY=$(secrethub read twdps/di/svc/aws/dps-2/DPSSimpleServiceAccount/aws-secret-access-key)
export EMAIL=$(secrethub read twdps/di/svc/gmail/email)

kubectl create secret generic twdps.io-${1}-secret -n cert-manager --from-literal=secret-access-key=$CM_AWS_SECRET_ACCESS_KEY

aws sts assume-role --output json --role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/DPSTerraformRole --role-session-name deploy-external-dns-session >credentials
export AWS_ACCESS_KEY_ID=$(cat credentials | jq -r ".Credentials.AccessKeyId")
export AWS_SECRET_ACCESS_KEY=$(cat credentials | jq -r ".Credentials.SecretAccessKey")
export AWS_SESSION_TOKEN=$(cat credentials | jq -r ".Credentials.SessionToken")
export AWS_DEFAULT_REGION=us-east-2
export host=twdps.io

export HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name $host | jq -r --arg DNS $host '.HostedZones[] | select( .Name | startswith($DNS)) | .Id')
export ISSUER_ENDPOINT=$(cat tpl/${1}.json | jq -r '.issuerEndpoint')
export cluster=$1
export environ=$2
export HOST=$(cat tpl/$cluster.json | jq -r '.host')


cat <<EOF >certificate_configuration.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ${HOST}-issuer
spec:
  acme:
    email: $EMAIL
    server: $ISSUER_ENDPOINT
    privateKeySecretRef:
      name: ${HOST}-certificate
    solvers:
    - dns01:
        route53:
          region: $AWS_DEFAULT_REGION
          hostedZoneID: $HOSTED_ZONE_ID
      selector:
        dnsZones:
          - ${HOST}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${HOST}-certificate
  namespace: istio-system
spec:
  secretName: ${HOST}-certificate
  issuerRef:
    name: ${HOST}-issuer
    kind: ClusterIssuer
  commonName: '*.${HOST}'
  dnsNames:
  - ${HOST}
  - '*.${HOST}'
EOF

kubectl apply -f certificate_configuration.yaml

sleep 10