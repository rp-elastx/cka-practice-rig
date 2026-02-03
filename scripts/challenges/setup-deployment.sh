#!/usr/bin/env bash
set -euo pipefail
NS="deploy-chal"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

cat <<'EOF' | kubectl -n "$NS" apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: web
          image: nginx:1.25
          ports:
            - containerPort: 80
          # Intentionally no resources
          resources: {}
EOF

echo "[setup-deployment] Deployment 'web' created in namespace '$NS'. Add CPU requests and configure HPA per challenge."