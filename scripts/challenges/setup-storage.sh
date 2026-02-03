#!/usr/bin/env bash
set -euo pipefail
NS="storage-chal"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

cat <<'EOF' | kubectl -n "$NS" apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: hint
  labels:
    app: hint
spec:
  containers:
    - name: hint
      image: busybox:1.36
      command: ["sh","-c","echo 'Create PVC data-pvc and mount at /data' && sleep 3600"]
      resources: {}
EOF

echo "[setup-storage] Namespace '$NS' ready. Create PVC 'data-pvc' and a pod 'app' mounting it at /data, writing OK to /data/ready.txt"