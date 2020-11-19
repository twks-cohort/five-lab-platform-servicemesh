#!/usr/bin/env bash

export namespace=$1

cat <<EOF > dev-namespaces.yaml
# create namespace
apiVersion: v1
kind: Namespace
metadata:
  name: $namespace
EOF

kubectl apply -f dev-namespaces.yaml

sleep 10