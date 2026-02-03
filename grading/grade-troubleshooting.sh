#!/usr/bin/env bash
set -euo pipefail
NS="trouble-chal"
DEPLOY="bad-app"

pass=true
msg=()

if ! kubectl -n "$NS" get deploy "$DEPLOY" >/dev/null 2>&1; then
  msg+=("Deployment '$DEPLOY' missing")
  pass=false
else
  if ! kubectl -n "$NS" rollout status deploy "$DEPLOY" --timeout=30s >/dev/null 2>&1; then
    msg+=("Deployment '$DEPLOY' not successfully rolled out")
    pass=false
  fi
  # Ensure at least one pod Ready
  ready=$(kubectl -n "$NS" get pods -l app=$DEPLOY -o jsonpath='{range .items[*]}{.status.containerStatuses[0].ready}{"\n"}{end}' | grep -c '^true$' || true)
  if [ "${ready:-0}" -lt 1 ]; then
    msg+=("No Ready pods for '$DEPLOY'")
    pass=false
  fi
fi

if $pass; then
  echo "PASS: troubleshoot-crashloop"
  exit 0
else
  echo "FAIL: troubleshoot-crashloop -> ${msg[*]}"
  exit 1
fi
