#!/usr/bin/env bash
set -euo pipefail
NS="netpol-complex"

pass=true
msg=()

# Check default deny policy
deny_count=$(kubectl -n "$NS" get networkpolicy -o json | jq '[.items[] | select(.spec.podSelector.matchLabels == {} or .spec.podSelector.matchLabels == null)] | length')
if [ "$deny_count" -eq 0 ]; then
  msg+=("Default deny NetworkPolicy missing")
  pass=false
fi

# Check allow-frontend policy
if ! kubectl -n "$NS" get networkpolicy allow-frontend >/dev/null 2>&1; then
  msg+=("NetworkPolicy 'allow-frontend' missing")
  pass=false
fi

# Check backend-policy
if ! kubectl -n "$NS" get networkpolicy backend-policy >/dev/null 2>&1; then
  msg+=("NetworkPolicy 'backend-policy' missing")
  pass=false
fi

# Check database-policy
if ! kubectl -n "$NS" get networkpolicy database-policy >/dev/null 2>&1; then
  msg+=("NetworkPolicy 'database-policy' missing")
  pass=false
fi

if $pass; then
  echo "PASS: network-policy-complex"
  exit 0
else
  echo "FAIL: network-policy-complex -> ${msg[*]}"
  exit 1
fi
