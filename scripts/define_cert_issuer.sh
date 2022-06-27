#!/usr/bin/env bash
set -e

export CLUSTER=$1
export AWS_DEFAULT_REGION=$(cat $CLUSTER.auto.tfvars.json | jq -r .aws_region)
export AWS_ACCOUNT_ID=$(cat $CLUSTER.auto.tfvars.json | jq -r .aws_account_id)
export AWS_ASSUME_ROLE=DPSPlatformHostedZonesRole

export CLUSTER_DOMAINS=$(cat environments/$CLUSTER.install.json | jq -r .cluster_domains)
export EMAIL=$(cat environments/$CLUSTER.install.json | jq -r '.issuerEmail')
export ISSUER_ENDPOINT=$(cat environments/$CLUSTER.install.json | jq -r '.issuerEndpoint')

aws sts assume-role --output json --role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/$AWS_ASSUME_ROLE --role-session-name lab-platform-servicemesh > credentials

export AWS_ACCESS_KEY_ID=$(cat credentials | jq -r ".Credentials.AccessKeyId")
export AWS_SECRET_ACCESS_KEY=$(cat credentials | jq -r ".Credentials.SecretAccessKey")
export AWS_SESSION_TOKEN=$(cat credentials | jq -r ".Credentials.SessionToken")

cat <<EOF > ${CLUSTER}-cluster-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-$CLUSTER-issuer
spec:
  acme:
    server: $ISSUER_ENDPOINT
    email: $EMAIL
    privateKeySecretRef:
      name: letsencrypt-$CLUSTER
    solvers:
EOF


declare -a domains=($(echo $CLUSTER_DOMAINS | jq -r '.[]'))

for domain in "${domains[@]}";
do
  export ZONE_ID=$(aws route53 list-hosted-zones-by-name | jq --arg name "$domain." -r '.HostedZones | .[] | select(.Name=="\($name)") | .Id')
  cat <<EOF >> ${CLUSTER}-cluster-issuer.yaml
    - selector:
        dnsZones:
          - "$domain"
      dns01:
        route53:
          region: ${AWS_DEFAULT_REGION}
          hostedZoneID: ${ZONE_ID}
EOF
done
