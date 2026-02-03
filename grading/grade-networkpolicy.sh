#!/usr/bin/env bash
set -euo pipefail
NS="netpol-chal"

pass=true
msg=()

# Check a NetworkPolicy targets app=server
np_names=$(kubectl -n "$NS" get netpol -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
if [ -z "$np_names" ]; then
  msg+=("No NetworkPolicy found")
  pass=false
else
  # Find a policy with podSelector app=server
  found=false
  for np in $np_names; do
    sel=$(kubectl -n "$NS" get netpol "$np" -o jsonpath='{.spec.podSelector.matchLabels.app}')
    if [ "$sel" = "server" ]; then
      # Check ingress rules allow from app=client on port 80 only
      fromSel=$(kubectl -n "$NS" get netpol "$np" -o jsonpath='{.spec.ingress[0].from[0].podSelector.matchLabels.app}')
      port=$(kubectl -n "$NS" get netpol "$np" -o jsonpath='{.spec.ingress[0].ports[0].port}')
      proto=$(kubectl -n "$NS" get netpol "$np" -o jsonpath='{.spec.ingress[0].ports[0].protocol}')
      if [ "$fromSel" = "client" ] && [ "$port" = "80" ] && [ "$proto" = "TCP" ]; then
        found=true
        break
      fi
    fi
  done
  if ! $found; then
    msg+=("No policy restricts to client on TCP 80 for server pods")
    pass=false
  fi
fi

if $pass; then
  echo "PASS: netpol-restrict"
  exit 0
else
  echo "FAIL: netpol-restrict -> ${msg[*]}"
  exit 1
fi
