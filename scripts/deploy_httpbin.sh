#!/usr/bin/env bash

export CLUSTER=$1
export DOMAIN=$2

cat <<EOF > httpbin.$CLUSTER.$DOMAIN.yaml
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
  namespace: default-mtls
spec:
  hosts:
  - "httpbin.$CLUSTER.$DOMAIN"
  gateways:
  - istio-system/$CLUSTER-wildcard-gateway
  http:
    - route:
      - destination:
          host: httpbin.default-mtls.svc.cluster.local
          port:
            number: 8000

---
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  namespace: default-mtls
  labels:
    app: httpbin
spec:
  ports:
  - name: http
    port: 8000
    targetPort: 80
  selector:
    app: httpbin

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: httpbin
  namespace: default-mtls

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
  namespace: default-mtls
spec:
  replicas: 2
  selector:
    matchLabels:
      app: httpbin
  template:
    metadata:
      labels:
        app: httpbin
    spec:
      serviceAccountName: httpbin
      containers:
      - image: docker.io/kennethreitz/httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        ports:
        - containerPort: 80
EOF

kubectl apply -f httpbin.$CLUSTER.$DOMAIN.yaml
