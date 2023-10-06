#!/usr/bin/env bash
set -eu -o pipefail

rm -f ns.yaml pods.yaml secrets.yaml

NB=${1:-1024}

for i in $(seq 1 "$NB"); do
  cat <<EOF >> ns.yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: test-$i
  labels:
    kubernetes.io/name: test
EOF

  for j in $(seq 1 1); do
    cat <<EOF >> pods.yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: test-$j
  namespace: test-ns-$i
  labels:
    kubernetes.io/name: test
spec:
  containers:
  - name: empty
    image: public.ecr.aws/docker/library/alpine:latest
    command: ["sleep", "100000"]
    imagePullPolicy: IfNotPresent
EOF
  done

  for j in $(seq 1 4); do
    cat <<EOF >> secrets.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: test-$j
  namespace: test-$i
  annotations:
    kubernetes.io/description: $(tr -dc '[:alpha:]' < /dev/urandom | fold -w 1024 | head -n 1)
  labels:
    kubernetes.io/name: test
data: {}
EOF
  done
done
