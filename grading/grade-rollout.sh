#!/usr/bin/env bash
set -euo pipefail
NS="rollout-chal"

pass=true
msg=()

# Check deployment exists
if ! kubectl -n "$NS" get deployment webapp >/dev/null 2>&1; then
  msg+=("Deployment 'webapp' missing")
  pass=false
else
  # Check image is nginx:1.23 (rolled back)
  image=$(kubectl -n "$NS" get deployment webapp -o jsonpath='{.spec.template.spec.containers[0].image}')
  if [ "$image" != "nginx:1.23" ]; then
    msg+=("Deployment 'webapp' not rolled back to nginx:1.23 (has $image)")
    pass=false
  fi
  
  # Check replicas
  replicas=$(kubectl -n "$NS" get deployment webapp -o jsonpath='{.spec.replicas}')
  if [ "$replicas" != "5" ]; then
    msg+=("Deployment 'webapp' not scaled to 5 replicas (has $replicas)")
    pass=false
  fi
fi

# Check rollout history file
if [ ! -f /tmp/rollout-history.txt ]; then
  msg+=("Output file /tmp/rollout-history.txt not found")
  pass=false
fi

if $pass; then
  echo "PASS: deployment-rollback"
  exit 0
else
  echo "FAIL: deployment-rollback -> ${msg[*]}"
  exit 1
fi
