#!/usr/bin/env bash
set -euo pipefail
NS="trouble-chal"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

cat <<'EOF' | kubectl -n "$NS" apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bad-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bad-app
  template:
    metadata:
      labels:
        app: bad-app
    spec:
      containers:
        - name: app
          image: busybox:1.36
          command: ["sh","-c","echo 'starting' && exit 1"]
          readinessProbe:
            exec:
              command: ["sh","-c","test -f /tmp/ready"]
            initialDelaySeconds: 2
            periodSeconds: 5
EOF

echo "[setup-troubleshooting] Deployment 'bad-app' created and will CrashLoop. Fix so pod becomes Ready (e.g., adjust command/args or probes)."