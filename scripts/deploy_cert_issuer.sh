#!/usr/bin/env bash
set -e

export CLUSTER=$1
export PROD_ACCOUNT_ID=$(cat $CLUSTER.cert-manager.json | jq -r .prod_account_id)
export AWS_DEFAULT_REGION=$(cat $CLUSTER.auto.tfvars.json | jq -r .aws_region)
export AWS_ASSUME_ROLE=$(cat $CLUSTER.auto.tfvars.json | jq -r .assume_role)
export DOMAIN=$(cat environments/${CLUSTER}.json | jq -r '.domain')
export EMAIL=$(cat environments/${CLUSTER}.json | jq -r '.issuerEmail')
export ISSUER_ENDPOINT=$(cat environments/${CLUSTER}.json | jq -r '.issuerEndpoint')

aws sts assume-role --output json --role-arn arn:aws:iam::$PROD_ACCOUNT_ID:role/$AWS_ASSUME_ROLE --role-session-name cluster-base-configuration-test > credentials

aws configure set aws_access_key_id $(cat credentials | jq -r ".Credentials.AccessKeyId") --profile $AWS_ASSUME_ROLE
aws configure set aws_secret_access_key $(cat credentials | jq -r ".Credentials.SecretAccessKey") --profile $AWS_ASSUME_ROLE
aws configure set aws_session_token $(cat credentials | jq -r ".Credentials.SessionToken") --profile $AWS_ASSUME_ROLE

export HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "$CLUSTER.$DOMAIN" --profile $AWS_ASSUME_ROLE | jq -r '.HostedZones[].Id')
#aws route53 list-hosted-zones-by-name --dns-name "twdps.io" | jq -r '.HostedZones[].Id'

export AWS_SECRET_ACCESS_KEY_BASE64=$(echo $AWS_SECRET_ACCESS_KEY | base64)

cat <<EOF > cert-issuer-credentials.yaml
apiVersion: v1
kind: Secret
metadata:
  name: route53-credentials
  namespace: istio-system
type: Opaque
data:
  secret-access-key: $AWS_SECRET_ACCESS_KEY_BASE64
EOF

kubectl apply -f cert-issuer-credentials.yaml

cat <<EOF > cluster_domain_certificate_issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-$CLUSTER-issuer
  namespace: istio-system
spec:
  acme:
    server: $ISSUER_ENDPOINT
    email: $EMAIL
    privateKeySecretRef:
      name: letsencrypt-$CLUSTER
    solvers:
    - selector:
        dnsZones:
          - "$CLUSTER.$DOMAIN"
      dns01:
        route53:
          region: $AWS_DEFAULT_REGION
          hostedZoneID: $HOSTED_ZONE_ID
          accessKeyID: $AWS_ACCESS_KEY_ID
          secretAccessKeySecretRef:
            name: route53-credentials
            key: secret-access-key
          role: "arn:aws:iam::$PROD_ACCOUNT_ID:role/$AWS_ASSUME_ROLE"
EOF

kubectl apply -f cluster_domain_certificate_issuer.yaml
