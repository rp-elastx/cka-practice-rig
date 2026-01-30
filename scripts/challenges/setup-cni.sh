#!/usr/bin/env bash
set -euo pipefail

echo "[setup-cni] Validate or install a CNI (kind already has kindnet). For Calico or Cilium, apply vendor manifests cluster-wide (optional)."