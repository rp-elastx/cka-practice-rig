#!/usr/bin/env bash
set -euo pipefail
NS="affinity-chal"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

echo "[setup-affinity] Namespace '$NS' ready."
echo "Label nodes and create pods with nodeSelector/nodeAffinity as described."
