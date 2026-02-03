#!/usr/bin/env bash
set -euo pipefail
NS="gateway-chal"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

# Install Gateway API CRDs if not present
if ! kubectl get crds | grep -q 'gateway.networking.k8s.io'; then
  kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml
fi

echo "[setup-gateway] Create a Gateway and HTTPRoute in '$NS' routing to a Service; verify route backendRefs point to Service."