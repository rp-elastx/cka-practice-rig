#!/usr/bin/env bash
set -euo pipefail
NS="resources-chal"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

echo "[setup-resources] Namespace '$NS' ready."
echo "Create pods with resource limits, LimitRange, and ResourceQuota as described."
