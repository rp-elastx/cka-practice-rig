#!/usr/bin/env bash
set -euo pipefail
NS="pv-chal"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

# Create an existing PV with Delete policy
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-existing
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  hostPath:
    path: /data/existing
EOF

echo "[setup-pv-policy] Namespace '$NS' ready with existing PV."
echo "Create PVs with different reclaim policies as described."
