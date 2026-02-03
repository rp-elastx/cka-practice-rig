#!/usr/bin/env bash
set -euo pipefail
NS="rollout-chal"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

# Create webapp deployment with nginx:1.23
kubectl -n "$NS" apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: nginx
        image: nginx:1.23
        ports:
        - containerPort: 80
EOF

kubectl -n "$NS" rollout status deployment/webapp

echo "[setup-rollout] Namespace '$NS' ready with webapp deployment (nginx:1.23)."
echo "Update, check history, rollback as described."
