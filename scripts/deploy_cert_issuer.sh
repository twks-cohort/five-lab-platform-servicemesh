#!/usr/bin/env bash
set -e

export CLUSTER=$1
export AWS_DEFAULT_REGION=$(cat $CLUSTER.auto.tfvars.json | jq -r .aws_region)
export AWS_ASSUME_ROLE=$(cat $CLUSTER.auto.tfvars.json | jq -r .assume_role)

export SAME_ACCOUNT_DOMAIN=$(cat $CLUSTER.json | jq -r '.same_account_domain')
export SAME_ACCOUNT_DOMAIN_ID=$(cat $CLUSTER.auto.tfvars.json | jq -r .account_id)
export CROSS_ACCOUNT_DOMAIN=$(cat $CLUSTER.json | jq -r '.cross_account_domain')

export EMAIL=$(cat $CLUSTER.json | jq -r '.issuerEmail')
export ISSUER_ENDPOINT=$(cat $CLUSTER.json | jq -r '.issuerEndpoint')

aws sts assume-role --output json --role-arn arn:aws:iam::$SAME_ACCOUNT_DOMAIN_ID:role/$AWS_ASSUME_ROLE --role-session-name deploy-cert-issuer > credentials

aws configure set aws_access_key_id $(cat credentials | jq -r ".Credentials.AccessKeyId") --profile $SAME_ACCOUNT_DOMAIN
aws configure set aws_secret_access_key $(cat credentials | jq -r ".Credentials.SecretAccessKey") --profile $SAME_ACCOUNT_DOMAIN
aws configure set aws_session_token $(cat credentials | jq -r ".Credentials.SessionToken") --profile $SAME_ACCOUNT_DOMAIN

export SAME_ACCOUNT_HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --profile $SAME_ACCOUNT_DOMAIN | jq --arg name "$CLUSTER.$SAME_ACCOUNT_DOMAIN." -r '.HostedZones | .[] | select(.Name=="\($name)") | .Id')
export CROSS_ACCOUNT_HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --profile $SAME_ACCOUNT_DOMAIN | jq --arg name "$CLUSTER.$CROSS_ACCOUNT_DOMAIN." -r '.HostedZones | .[] | select(.Name=="\($name)") | .Id')

cat <<EOF > ${CLUSTER}-cluster-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-$CLUSTER-issuer
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: twdps.io@gmail.com
    privateKeySecretRef:
      name: letsencrypt-sandbox
    solvers:
    - selector:
        dnsZones:
          - "$CLUSTER.$SAME_ACCOUNT_DOMAIN"
      dns01:
        route53:
          region: ${AWS_DEFAULT_REGION}
          hostedZoneID: ${SAME_ACCOUNT_HOSTED_ZONE_ID}
    - selector:
        dnsZones:
          - "$CLUSTER.$CROSS_ACCOUNT_DOMAIN"
      dns01:
        route53:
          region: ${AWS_DEFAULT_REGION}
          hostedZoneID: ${CROSS_ACCOUNT_HOSTED_ZONE_ID}
EOF

kubectl apply -f ${CLUSTER}-cluster-issuer.yaml
