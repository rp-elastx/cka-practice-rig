#!/usr/bin/env bash
set -euo pipefail
NS="config-chal"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

echo "[setup-config] Namespace '$NS' ready."
echo "Create Secrets, ConfigMaps, and pods using them as described."
