#!/usr/bin/env bash
set -euo pipefail
NS="affinity-chal"

pass=true
msg=()

# Find worker node
WORKER=$(kubectl get nodes --no-headers | grep -v control-plane | awk '{print $1}' | head -1)

# Check node labels
if [ -n "$WORKER" ]; then
  disktype=$(kubectl get node "$WORKER" -o jsonpath='{.metadata.labels.disktype}')
  zone=$(kubectl get node "$WORKER" -o jsonpath='{.metadata.labels.zone}')
  if [ "$disktype" != "ssd" ]; then
    msg+=("Node '$WORKER' missing label disktype=ssd")
    pass=false
  fi
  if [ "$zone" != "east" ]; then
    msg+=("Node '$WORKER' missing label zone=east")
    pass=false
  fi
fi

# Check ssd-pod has nodeSelector
if ! kubectl -n "$NS" get pod ssd-pod >/dev/null 2>&1; then
  msg+=("Pod 'ssd-pod' missing")
  pass=false
else
  selector=$(kubectl -n "$NS" get pod ssd-pod -o jsonpath='{.spec.nodeSelector.disktype}')
  if [ "$selector" != "ssd" ]; then
    msg+=("Pod 'ssd-pod' missing nodeSelector disktype=ssd")
    pass=false
  fi
fi

# Check zone-app deployment
if ! kubectl -n "$NS" get deployment zone-app >/dev/null 2>&1; then
  msg+=("Deployment 'zone-app' missing")
  pass=false
else
  replicas=$(kubectl -n "$NS" get deployment zone-app -o jsonpath='{.spec.replicas}')
  if [ "$replicas" != "3" ]; then
    msg+=("Deployment 'zone-app' does not have 3 replicas")
    pass=false
  fi
fi

if $pass; then
  echo "PASS: node-affinity-selector"
  exit 0
else
  echo "FAIL: node-affinity-selector -> ${msg[*]}"
  exit 1
fi
