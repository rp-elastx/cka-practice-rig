#!/usr/bin/env bash
set -euo pipefail
NS="service-chal"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

cat <<'EOF' | kubectl -n "$NS" apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: echo
  labels:
    app: echo
spec:
  containers:
    - name: http-echo
      image: hashicorp/http-echo:0.2.3
      args: ["-text=hello","-listen=:8080"]
      ports:
        - containerPort: 8080
EOF

echo "[setup-service] Pod 'echo' ready in namespace '$NS'. Expose it via ClusterIP service 'echo-svc' port 8080."