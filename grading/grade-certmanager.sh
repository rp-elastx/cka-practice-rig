#!/usr/bin/env bash
set -euo pipefail
# Validate cert-manager CRDs are installed

pass=true
msg=()

crds=$(kubectl get crds -o name | grep -c 'cert-manager.io' || true)
if [ "${crds:-0}" -lt 1 ]; then
  msg+=("cert-manager CRDs not found")
  pass=false
fi

if $pass; then
  echo "PASS: certmanager"
  exit 0
else
  echo "FAIL: certmanager -> ${msg[*]}"
  exit 1
fi
