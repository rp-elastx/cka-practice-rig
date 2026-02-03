#!/usr/bin/env bash
set -euo pipefail
NS="sa-chal"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

# Create a test secret
kubectl -n "$NS" create secret generic test-secret --from-literal=key=value --dry-run=client -o yaml | kubectl apply -f -

echo "[setup-serviceaccount] Namespace '$NS' ready with a test secret."
echo "Create ServiceAccount, Role, RoleBinding, and Pod as described."
