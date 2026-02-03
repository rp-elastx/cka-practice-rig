#!/usr/bin/env bash
set -euo pipefail
NS="svc-chal"

pass=true
msg=()

# Check NodePort service
if ! kubectl -n "$NS" get svc webapp-nodeport >/dev/null 2>&1; then
  msg+=("Service 'webapp-nodeport' missing")
  pass=false
else
  stype=$(kubectl -n "$NS" get svc webapp-nodeport -o jsonpath='{.spec.type}')
  nodeport=$(kubectl -n "$NS" get svc webapp-nodeport -o jsonpath='{.spec.ports[0].nodePort}')
  if [ "$stype" != "NodePort" ]; then
    msg+=("Service 'webapp-nodeport' is not NodePort (is $stype)")
    pass=false
  fi
  if [ "$nodeport" != "30080" ]; then
    msg+=("Service 'webapp-nodeport' nodePort is not 30080 (is $nodeport)")
    pass=false
  fi
fi

# Check ClusterIP service
if ! kubectl -n "$NS" get svc webapp-internal >/dev/null 2>&1; then
  msg+=("Service 'webapp-internal' missing")
  pass=false
fi

# Check ExternalName service
if ! kubectl -n "$NS" get svc external-db >/dev/null 2>&1; then
  msg+=("Service 'external-db' missing")
  pass=false
else
  stype=$(kubectl -n "$NS" get svc external-db -o jsonpath='{.spec.type}')
  if [ "$stype" != "ExternalName" ]; then
    msg+=("Service 'external-db' is not ExternalName (is $stype)")
    pass=false
  fi
fi

if $pass; then
  echo "PASS: nodeport-service"
  exit 0
else
  echo "FAIL: nodeport-service -> ${msg[*]}"
  exit 1
fi
