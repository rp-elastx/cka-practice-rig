#!/usr/bin/env bash
set -euo pipefail
NS="ops"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

# Create the ServiceAccount
kubectl -n "$NS" create serviceaccount monitoring --dry-run=client -o yaml | kubectl apply -f -

echo "[setup-clusterrole] Namespace '$NS' ready with ServiceAccount 'monitoring'."
echo "Create ClusterRoles and ClusterRoleBindings as described."
