#!/usr/bin/env bash
set -euo pipefail

# Create some test pods with labels
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: jsonpath-test
---
apiVersion: v1
kind: Pod
metadata:
  name: web-1
  namespace: jsonpath-test
  labels:
    app: web
spec:
  containers:
  - name: nginx
    image: nginx:1.24
---
apiVersion: v1
kind: Pod
metadata:
  name: web-2
  namespace: jsonpath-test
  labels:
    app: web
spec:
  containers:
  - name: nginx
    image: nginx:1.24
EOF

echo "[setup-jsonpath] Test resources created."
echo "Use kubectl with JSONPath to extract and sort data as described."
