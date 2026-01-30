#!/usr/bin/env bash
set -euo pipefail
# Basic Helm grader: validates helm is installed and at least one release exists in the target namespace
NS=${1:-default}

pass=true
msg=()

if ! command -v helm >/dev/null 2>&1; then
  msg+=("helm not installed")
  pass=false
else
  # Use KUBECONFIG env; list releases in the namespace
  if ! helm list -n "$NS" >/dev/null 2>&1; then
    msg+=("cannot list helm releases in namespace '$NS'")
    pass=false
  else
    count=$(helm list -n "$NS" -o json | python3 -c "import sys,json;print(len(json.load(sys.stdin)))")
    if [ "${count:-0}" -lt 1 ]; then
      msg+=("no helm releases found in '$NS'")
      pass=false
    fi
  fi
fi

if $pass; then
  echo "PASS: helm"
  exit 0
else
  echo "FAIL: helm -> ${msg[*]}"
  exit 1
fi
