#!/usr/bin/env bash
set -euo pipefail
NS="quota-chal"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

echo "[setup-quota] Create a ResourceQuota in '$NS' limiting requests.cpu and requests.memory; then ensure pods adhere to requests settings."