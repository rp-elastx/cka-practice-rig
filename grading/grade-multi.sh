#!/usr/bin/env bash
set -euo pipefail
NS="multi-chal"

pass=true
msg=()

# Check web-with-init pod
if ! kubectl -n "$NS" get pod web-with-init >/dev/null 2>&1; then
  msg+=("Pod 'web-with-init' missing")
  pass=false
else
  # Check init container
  initName=$(kubectl -n "$NS" get pod web-with-init -o jsonpath='{.spec.initContainers[0].name}')
  if [ "$initName" != "init-data" ]; then
    msg+=("Pod 'web-with-init' missing init container 'init-data'")
    pass=false
  fi
  
  # Check pod is running
  ready=$(kubectl -n "$NS" get pod web-with-init -o jsonpath='{.status.phase}')
  if [ "$ready" != "Running" ]; then
    msg+=("Pod 'web-with-init' not Running (is $ready)")
    pass=false
  fi
fi

# Check sidecar-logger pod
if ! kubectl -n "$NS" get pod sidecar-logger >/dev/null 2>&1; then
  msg+=("Pod 'sidecar-logger' missing")
  pass=false
else
  # Check has 2 containers
  count=$(kubectl -n "$NS" get pod sidecar-logger -o jsonpath='{.spec.containers}' | jq '. | length')
  if [ "$count" != "2" ]; then
    msg+=("Pod 'sidecar-logger' does not have 2 containers (has $count)")
    pass=false
  fi
fi

if $pass; then
  echo "PASS: multi-container-pod"
  exit 0
else
  echo "FAIL: multi-container-pod -> ${msg[*]}"
  exit 1
fi
