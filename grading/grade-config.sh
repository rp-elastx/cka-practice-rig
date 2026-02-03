#!/usr/bin/env bash
set -euo pipefail
NS="config-chal"

pass=true
msg=()

# Check Secret
if ! kubectl -n "$NS" get secret db-secret >/dev/null 2>&1; then
  msg+=("Secret 'db-secret' missing")
  pass=false
fi

# Check ConfigMap
if ! kubectl -n "$NS" get configmap app-config >/dev/null 2>&1; then
  msg+=("ConfigMap 'app-config' missing")
  pass=false
fi

# Check Pod
if ! kubectl -n "$NS" get pod config-pod >/dev/null 2>&1; then
  msg+=("Pod 'config-pod' missing")
  pass=false
else
  # Check pod has env vars from secret
  envFrom=$(kubectl -n "$NS" get pod config-pod -o jsonpath='{.spec.containers[0].env}')
  if ! echo "$envFrom" | grep -q "DB_USER"; then
    msg+=("Pod 'config-pod' missing DB_USER env var")
    pass=false
  fi
  
  # Check pod has volume mount
  mount=$(kubectl -n "$NS" get pod config-pod -o jsonpath='{.spec.containers[0].volumeMounts[*].mountPath}')
  if ! echo "$mount" | grep -q "/etc/config"; then
    msg+=("Pod 'config-pod' not mounting /etc/config")
    pass=false
  fi
  
  # Check pod is running
  ready=$(kubectl -n "$NS" get pod config-pod -o jsonpath='{.status.phase}')
  if [ "$ready" != "Running" ]; then
    msg+=("Pod 'config-pod' not Running (is $ready)")
    pass=false
  fi
fi

if $pass; then
  echo "PASS: secret-configmap-env"
  exit 0
else
  echo "FAIL: secret-configmap-env -> ${msg[*]}"
  exit 1
fi
