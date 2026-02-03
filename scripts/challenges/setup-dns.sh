#!/usr/bin/env bash
set -euo pipefail
NS="dns-chal"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

# Create a service to test DNS
kubectl -n "$NS" apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: web-svc
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: web
  labels:
    app: web
spec:
  containers:
  - name: nginx
    image: nginx:1.24
EOF

echo "[setup-dns] Namespace '$NS' ready with web service."
echo "Test DNS resolution as described."
