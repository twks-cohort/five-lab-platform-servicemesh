#!/usr/bin/env bash

export CLUSTER=$1

cat <<EOF >httpbin-twdps-io-gateway.yaml
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: httpbin
  namespace: lab-system-mtls
spec:
  hosts:
  - "httpbin.$CLUSTER.cohortscdi-five.com"
  gateways:
  - istio-system/$CLUSTER-cohortscdi-five-com-gateway
  http:
    - route:
      - destination:
          host: httpbin.lab-system-mtls.svc.cluster.local
          port:
            number: 8000

---
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  namespace: lab-system-mtls
  labels:
    app: httpbin
spec:
  ports:
  - name: http-port
    port: 8000
    targetPort: 80
  selector:
    app: httpbin

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: httpbin
  namespace: lab-system-mtls

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
  namespace: lab-system-mtls
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

kubectl apply -f httpbin-twdps-io-gateway.yaml
