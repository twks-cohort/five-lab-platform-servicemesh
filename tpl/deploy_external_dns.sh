#!/usr/bin/env bash

# need to parameterize the account-id
export AWS_ACCOUNT_ID=$(secrethub read twdps/di/svc/aws/dps-2/aws-account-id)

aws sts assume-role --output json --role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/DPSTerraformRole --role-session-name deploy-external-dns-session >credentials
export AWS_ACCESS_KEY_ID=$(cat credentials | jq -r ".Credentials.AccessKeyId")
export AWS_SECRET_ACCESS_KEY=$(cat credentials | jq -r ".Credentials.SecretAccessKey")
export AWS_SESSION_TOKEN=$(cat credentials | jq -r ".Credentials.SessionToken")
export AWS_DEFAULT_REGION=us-west-2
export cluster=$1

# paramterize cluster hosted zone

export HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name $host | jq -r --arg DNS $host '.HostedZones[] | select( .Name | startswith($DNS)) | .Id')

# external-dns deployment files
cat <<EOF >external-dns-deployment.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${1}-external-dns
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::${AWS_ACCOUNT_ID}:role/${1}-external-dns

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: external-dns
  namespace: kube-system
rules:
- apiGroups: [""]
  resources: ["services","endpoints","pods"]
  verbs: ["get","watch","list"]
- apiGroups: ["extensions","networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get","watch","list"]
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["list","watch"]
- apiGroups: ["networking.istio.io"]
  resources: ["gateways", "virtualservices"]
  verbs: ["get","watch","list"]

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: external-dns-viewer
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-dns
subjects:
- kind: ServiceAccount
  name: ${1}-external-dns
  namespace: kube-system

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
  namespace: kube-system
spec:
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: external-dns
  template:
    metadata:
      labels:
        app: external-dns
    spec:
      serviceAccountName: ${1}-external-dns
      containers:
      - name: external-dns
        image: k8s.gcr.io/external-dns/external-dns:v0.7.4
        args:
        - --source=service
        - --source=ingress
        - --source=istio-gateway
        - --source=istio-virtualservice
        - --domain-filter=$host
        - --provider=aws
        # - --policy=upsert-only # would prevent ExternalDNS from deleting any records, omit to enable full synchronization
        - --aws-zone-type=public # only look at public hosted zones (valid values are public, private or no value for both)
        - --registry=txt
        - --txt-owner-id=${HOSTED_ZONE_ID}
      securityContext:
        fsGroup: 65534 # For ExternalDNS to be able to read Kubernetes and AWS token files
EOF
kubectl apply -f external-dns-deployment.yaml

sleep 10
