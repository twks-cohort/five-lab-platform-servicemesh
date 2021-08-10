#!/usr/bin/env bash
set -e

export CLUSTER=$1
export AWS_ACCOUNT_ID=$(cat $CLUSTER.auto.tfvars.json | jq -r .account_id)
export EXTERNAL_DNS_VERSION=$(cat $CLUSTER.json | jq -r .external_dns_version)
export SAME_ACCOUNT_DOMAIN=$(cat $CLUSTER.json | jq -r .same_account_domain)
export CROSS_ACCOUNT_DOMAIN=$(cat $CLUSTER.json | jq -r .cross_account_domain)

cat <<EOF > external-dns-deployment.yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $CLUSTER-external-dns
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::${AWS_ACCOUNT_ID}:role/${CLUSTER}-external-dns

---
apiVersion: rbac.authorization.k8s.io/v1
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
apiVersion: rbac.authorization.k8s.io/v1
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
  name: ${CLUSTER}-external-dns
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
      serviceAccountName: $CLUSTER-external-dns
      containers:
      - name: external-dns
        image: k8s.gcr.io/external-dns/external-dns:v${EXTERNAL_DNS_VERSION}
        args:
        - --source=service
        - --source=ingress
        - --source=istio-gateway
        - --source=istio-virtualservice
        - --domain-filter=${CLUSTER}.${SAME_ACCOUNT_DOMAIN}
        - --domain-filter=${CLUSTER}.${CROSS_ACCOUNT_DOMAIN}
        - --provider=aws
        # - --policy=upsert-only # would prevent ExternalDNS from deleting any records, omit to enable full synchronization
        - --aws-zone-type=public # only look at public hosted zones (valid values are public, private or no value for both)
        - --registry=txt
        - --txt-owner-id=${CLUSTER}-twdps-labs
      securityContext:
        fsGroup: 65534 # For ExternalDNS to be able to read Kubernetes and AWS token files
EOF

kubectl apply -f external-dns-deployment.yaml

sleep 10
