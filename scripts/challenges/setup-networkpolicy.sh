#!/usr/bin/env bash
set -euo pipefail
NS="netpol-chal"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

cat <<'EOF' | kubectl -n "$NS" apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: server
  template:
    metadata:
      labels:
        app: server
    spec:
      containers:
        - name: web
          image: nginx:1.25
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: client
  labels:
    app: client
spec:
  containers:
    - name: curl
      image: curlimages/curl:8.5.0
      command: ["sh","-c","sleep 3600"]
EOF

echo "[setup-networkpolicy] 'server' and 'client' created in '$NS'. Create a NetworkPolicy to allow only 'client' to reach 'server' on TCP 80."