#!/usr/bin/env bash
set -euo pipefail
NS="helm-chal"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

echo "[setup-helm] Install a chart into namespace '$NS' using Helm. Example: helm repo add bitnami https://charts.bitnami.com/bitnami && helm install demo bitnami/nginx -n '$NS'"