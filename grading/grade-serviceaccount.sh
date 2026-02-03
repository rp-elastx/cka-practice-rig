#!/usr/bin/env bash
set -euo pipefail
NS="sa-chal"

pass=true
msg=()

# Check ServiceAccount
if ! kubectl -n "$NS" get serviceaccount app-sa >/dev/null 2>&1; then
  msg+=("ServiceAccount 'app-sa' missing")
  pass=false
fi

# Check Role
if ! kubectl -n "$NS" get role secret-reader >/dev/null 2>&1; then
  msg+=("Role 'secret-reader' missing")
  pass=false
fi

# Check RoleBinding
if ! kubectl -n "$NS" get rolebinding app-secret-binding >/dev/null 2>&1; then
  msg+=("RoleBinding 'app-secret-binding' missing")
  pass=false
fi

# Check Pod
if ! kubectl -n "$NS" get pod secret-app >/dev/null 2>&1; then
  msg+=("Pod 'secret-app' missing")
  pass=false
else
  sa=$(kubectl -n "$NS" get pod secret-app -o jsonpath='{.spec.serviceAccountName}')
  if [ "$sa" != "app-sa" ]; then
    msg+=("Pod 'secret-app' does not use ServiceAccount 'app-sa'")
    pass=false
  fi
  ready=$(kubectl -n "$NS" get pod secret-app -o jsonpath='{.status.containerStatuses[0].ready}')
  if [ "$ready" != "true" ]; then
    msg+=("Pod 'secret-app' not Ready")
    pass=false
  fi
fi

if $pass; then
  echo "PASS: serviceaccount-pod"
  exit 0
else
  echo "FAIL: serviceaccount-pod -> ${msg[*]}"
  exit 1
fi
