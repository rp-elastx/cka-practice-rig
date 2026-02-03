#!/usr/bin/env bash
set -euo pipefail
NS="netpol-complex"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

# Create test pods for different tiers
kubectl -n "$NS" apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  labels:
    tier: frontend
spec:
  containers:
  - name: nginx
    image: nginx:1.24
---
apiVersion: v1
kind: Pod
metadata:
  name: backend
  labels:
    tier: backend
spec:
  containers:
  - name: nginx
    image: nginx:1.24
---
apiVersion: v1
kind: Pod
metadata:
  name: database
  labels:
    tier: database
spec:
  containers:
  - name: postgres
    image: postgres:15
    env:
    - name: POSTGRES_PASSWORD
      value: password
EOF

echo "[setup-netpol-complex] Namespace '$NS' ready with frontend/backend/database pods."
echo "Create NetworkPolicies as described."
