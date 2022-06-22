#!/usr/bin/env bash
set -e

export CLUSTER=$1
export AWS_DEFAULT_REGION=$(cat $CLUSTER.auto.tfvars.json | jq -r .aws_region)
export AWS_ACCOUNT_ID=$(cat $CLUSTER.auto.tfvars.json | jq -r .aws_account_id)
export AWS_ASSUME_ROLE=$(cat $CLUSTER.auto.tfvars.json | jq -r .aws_assume_role)

export CLUSTER_DOMAINS=$(cat environments/$CLUSTER.install.json | jq -r .cluster_domains)
export EMAIL=$(cat environments/$CLUSTER.install.json | jq -r '.issuerEmail')
export ISSUER_ENDPOINT=$(cat environments/$CLUSTER.install.json | jq -r '.issuerEndpoint')

# aws sts assume-role --output json --role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/$AWS_ASSUME_ROLE --role-session-name lab-platform-servicemesh > credentials

# aws configure set aws_access_key_id $(cat credentials | jq -r ".Credentials.AccessKeyId")
# aws configure set aws_secret_access_key $(cat credentials | jq -r ".Credentials.SecretAccessKey")
# aws configure set aws_session_token $(cat credentials | jq -r ".Credentials.SessionToken")

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

kubectl apply -f ${CLUSTER}-cluster-issuer.yaml
