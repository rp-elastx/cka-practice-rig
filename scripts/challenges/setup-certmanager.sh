#!/usr/bin/env bash
set -euo pipefail

# Install cert-manager CRDs and controller (optional)
if ! kubectl get crds | grep -q 'cert-manager.io'; then
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.crds.yaml
fi

echo "[setup-certmanager] Ensure cert-manager is installed; list CRDs and describe key resources (ClusterIssuer, Certificate, etc.)."