#!/usr/bin/env bash
set -euo pipefail
NS="taint-chal"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

echo "[setup-taint] Namespace '$NS' ready."
echo "Add taints to nodes and create pods with tolerations as described."
