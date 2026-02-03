#!/usr/bin/env bash
set -euo pipefail
NS="svc-chal"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

# Create webapp deployment
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
        image: nginx:1.24
        ports:
        - containerPort: 80
EOF

echo "[setup-nodeport] Namespace '$NS' ready with webapp deployment."
echo "Create NodePort, ClusterIP, and ExternalName services as described."
