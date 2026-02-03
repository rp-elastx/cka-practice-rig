#!/usr/bin/env bash
set -euo pipefail
NS="logs-chal"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

# Create test pods
kubectl -n "$NS" apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: web-server
spec:
  containers:
  - name: nginx
    image: nginx:1.24
---
apiVersion: v1
kind: Pod
metadata:
  name: failing-app
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ['sh', '-c', 'echo "Starting app"; sleep 10; exit 1']
  restartPolicy: Always
EOF

echo "[setup-logs] Namespace '$NS' ready with test pods."
echo "Analyze logs and events as described."
