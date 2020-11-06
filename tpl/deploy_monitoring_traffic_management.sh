#!/usr/bin/env bash
export CLUSTER=${1}

cat <<EOF > monitoring-traffic-management.yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: monitoring-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
        - "istio-system.$CLUSTER.twdps.io"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: kiali-virtual-service
  namespace: istio-system
spec:
  hosts:
    - "istio-system.$CLUSTER.twdps.io"
  gateways:
    - monitoring-gateway
  http:
    - match:
        - uri:
            prefix: /kiali/
      route:
      - destination:
          host: kiali
          port:
            number: 20001
EOF
kubectl apply -f monitoring-traffic-management.yaml

sleep 10
