#!/usr/bin/env bash
set -euo pipefail
NS="rbac-chal"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

echo "[setup-rbac] Namespace '$NS' ready. Create Role 'pod-reader' and RoleBinding 'read-pods' binding User 'student'."