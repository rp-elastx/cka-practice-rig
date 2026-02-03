#!/usr/bin/env bash
set -euo pipefail
NS="taint-chal"

pass=true
msg=()

# Find worker node
WORKER=$(kubectl get nodes --no-headers | grep -v control-plane | awk '{print $1}' | head -1)

if [ -n "$WORKER" ]; then
  # Check gpu taint exists
  taints=$(kubectl get node "$WORKER" -o jsonpath='{.spec.taints}')
  if ! echo "$taints" | grep -q "dedicated"; then
    msg+=("Node '$WORKER' missing taint 'dedicated=gpu:NoSchedule'")
    pass=false
  fi
fi

# Check gpu-pod has toleration
if ! kubectl -n "$NS" get pod gpu-pod >/dev/null 2>&1; then
  msg+=("Pod 'gpu-pod' missing")
  pass=false
else
  tolerations=$(kubectl -n "$NS" get pod gpu-pod -o jsonpath='{.spec.tolerations}')
  if ! echo "$tolerations" | grep -q "dedicated"; then
    msg+=("Pod 'gpu-pod' missing toleration for 'dedicated'")
    pass=false
  fi
fi

# Check tolerant-app deployment
if ! kubectl -n "$NS" get deployment tolerant-app >/dev/null 2>&1; then
  msg+=("Deployment 'tolerant-app' missing")
  pass=false
fi

# Check node-taints.txt
if [ ! -f /tmp/node-taints.txt ]; then
  msg+=("Output file /tmp/node-taints.txt not found")
  pass=false
fi

if $pass; then
  echo "PASS: taint-toleration"
  exit 0
else
  echo "FAIL: taint-toleration -> ${msg[*]}"
  exit 1
fi
