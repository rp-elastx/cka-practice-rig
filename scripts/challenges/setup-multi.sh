#!/usr/bin/env bash
set -euo pipefail
NS="multi-chal"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

echo "[setup-multi] Namespace '$NS' ready."
echo "Create multi-container pods with init containers and sidecars as described."
