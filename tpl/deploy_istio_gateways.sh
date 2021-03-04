#!/usr/bin/env bash
export CLUSTER=${1}

cat <<EOF > istio-gateways.yaml
---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: $CLUSTER-gateway
  namespace: istio-system
  labels:
    istio: istio-ingressgateway
spec:
  selector:
    istio: istio-ingressgateway
  servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
        - '*'

---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: istio-tools-gateway
  namespace: istio-system
spec:
  selector:
    istio: istio-ingressgateway
  servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
        - istio-system.$CLUSTER.twdps.io
        
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: kiali-virtual-service
  namespace: istio-system
spec:
  hosts:
    - istio-system.$CLUSTER.twdps.io
  gateways:
    - istio-tools-gateway
  http:
    - match:
        - uri:
            prefix: /kiali/
      route:
      - destination:
          host: kiali
          port:
            number: 20001

---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: jaeger
  namespace: istio-system
spec:
  hosts:
    - istio-system.$CLUSTER.twdps.io
  gateways:
    - istio-tools-gateway
  http:
    - match:
      - uri:
          prefix: /jaeger/
      route:
      - destination:
          host: tracing
          port:
            number: 80
EOF
kubectl apply -f istio-gateways.yaml

sleep 10
