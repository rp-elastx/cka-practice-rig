#!/usr/bin/env bash
set -euo pipefail
NS="drain-chal"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

# Create a deployment to be drained
kubectl -n "$NS" apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: drain-test
spec:
  replicas: 2
  selector:
    matchLabels:
      app: drain-test
  template:
    metadata:
      labels:
        app: drain-test
    spec:
      containers:
      - name: nginx
        image: nginx:1.24
EOF

echo "[setup-drain] Namespace '$NS' ready with test deployment."
echo "Cordon, drain, and uncordon the worker node."
