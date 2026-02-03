#!/usr/bin/env bash
set -euo pipefail
NS="service-chal"
POD="echo"
SVC="echo-svc"

pass=true
msg=()

if ! kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1; then
  msg+=("Pod '$POD' missing")
  pass=false
fi

if ! kubectl -n "$NS" get svc "$SVC" >/dev/null 2>&1; then
  msg+=("Service '$SVC' missing")
  pass=false
else
  # Check selector matches
  sel=$(kubectl -n "$NS" get svc "$SVC" -o jsonpath='{.spec.selector.app}')
  if [ "$sel" != "echo" ]; then
    msg+=("Service selector not app=echo (got app=$sel)")
    pass=false
  fi
  # Check endpoints exist
  if ! kubectl -n "$NS" get endpoints "$SVC" -o jsonpath='{.subsets[0].addresses[0].ip}' >/dev/null 2>&1; then
    msg+=("Service endpoints not ready")
    pass=false
  fi
fi

if $pass; then
  echo "PASS: service-basic"
  exit 0
else
  echo "FAIL: service-basic -> ${msg[*]}"
  exit 1
fi
