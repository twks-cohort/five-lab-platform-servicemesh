#!/usr/bin/env bash
set -e

export CLUSTER=$1
export AWS_ACCOUNT_ID=$(cat $CLUSTER.auto.tfvars.json | jq -r .aws_account_id)

export EXTERNAL_DNS_VERSION=$(cat environments/$CLUSTER.install.json | jq -r .external_dns_version)
export CLUSTER_DOMAINS=$(cat environments/$CLUSTER.install.json | jq -r .cluster_domains)

declare -a domains=($(echo $CLUSTER_DOMAINS | jq -r '.[]'))
export SOURCE_PATCH=""
NL=$'\n'

for domain in "${domains[@]}";
do
  export SOURCE_PATCH="          - --domain-filter=${domain}${NL}${SOURCE_PATCH}"
done
export SOURCE_PATCH=${SOURCE_PATCH%$'\n'}

cat <<EOF > external-dns/service-account.yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-dns
  namespace: istio-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::${AWS_ACCOUNT_ID}:role/${CLUSTER}-external-dns
EOF

cat <<EOF > external-dns/service.yaml
---
apiVersion: v1
kind: Service
metadata:
  name: external-dns
  namespace: istio-system
spec:
  type: ClusterIP
  selector:
    name: external-dns
  ports:
    - name: http
      port: 7979
      targetPort: http
      protocol: TCP
EOF

cat <<EOF > external-dns/role-bindings.yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-dns
rules:
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["get","watch","list"]
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get","watch","list"]
  - apiGroups: ["extensions","networking","networking.k8s.io"]
    resources: ["ingresses"]
    verbs: ["get","watch","list"]
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get","watch","list"]
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get","watch","list"]
  - apiGroups: ["networking.istio.io"]
    resources: ["gateways", "virtualservices"]
    verbs: ["get","watch","list"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-dns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-dns
subjects:
- kind: ServiceAccount
  name: external-dns
  namespace: istio-system
EOF

cat <<EOF > external-dns/deployment.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
  namespace: istio-system
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
      serviceAccountName: external-dns
      containers:
      - name: external-dns
        image: k8s.gcr.io/external-dns/external-dns:v${EXTERNAL_DNS_VERSION}
        args:
          - --source=service
          - --source=ingress
          - --source=istio-gateway
          - --source=istio-virtualservice
${SOURCE_PATCH}
          - --provider=aws
          - --aws-zone-type=public # only look at public hosted zones (valid values are public, private or no value for both)
          - --registry=txt
          - --txt-owner-id=${CLUSTER}-twdps-labs
          - --log-format=json
        ports:
          - name: http
            protocol: TCP
            containerPort: 7979
        livenessProbe:
          failureThreshold: 2
          httpGet:
            path: /healthz
            port: http
          initialDelaySeconds: 10
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 5
        readinessProbe:
          failureThreshold: 6
          httpGet:
            path: /healthz
            port: http
          initialDelaySeconds: 5
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 5
      securityContext:
        fsGroup: 65534 # For ExternalDNS to be able to read Kubernetes and AWS token files
EOF

kubectl apply -f external-dns/ --recursive

# sleep 10
