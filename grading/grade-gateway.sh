#!/usr/bin/env bash
set -euo pipefail
# Validate Gateway API objects exist and route to a service
NS=${1:-default}

pass=true
msg=()

# Gateway or HTTPRoute present
gtw=$(kubectl -n "$NS" get gateway.gateway.networking.k8s.io -o name 2>/dev/null | wc -l || echo 0)
routes=$(kubectl -n "$NS" get httproute.gateway.networking.k8s.io -o name 2>/dev/null | wc -l || echo 0)
if [ "$gtw" -lt 1 ] && [ "$routes" -lt 1 ]; then
  msg+=("no Gateway API objects found in '$NS'")
  pass=false
else
  # Ensure at least one HTTPRoute backendRef points to a Service
  if [ "$routes" -gt 0 ]; then
    ok=$(kubectl -n "$NS" get httproute -o json | python3 - <<'PY'
import sys,json
j=json.load(sys.stdin)
for r in j['items']:
  for rr in r.get('spec',{}).get('rules',[]):
    for b in rr.get('backendRefs',[]):
      if b.get('kind','Service')=='Service':
        print('YES');sys.exit(0)
print('NO')
PY
)
    if [ "$ok" != "YES" ]; then
      msg+=("HTTPRoute does not reference Service backend")
      pass=false
    fi
  fi
fi

if $pass; then
  echo "PASS: gateway"
  exit 0
else
  echo "FAIL: gateway -> ${msg[*]}"
  exit 1
fi
