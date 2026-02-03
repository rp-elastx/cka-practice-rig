#!/usr/bin/env bash
set -euo pipefail
NS="storage-chal"
PVC="data-pvc"
POD="app"

pass=true
msg=()

if ! kubectl get ns "$NS" >/dev/null 2>&1; then
  msg+=("Namespace '$NS' missing")
  pass=false
fi

if ! kubectl -n "$NS" get pvc "$PVC" >/dev/null 2>&1; then
  msg+=("PVC '$PVC' missing")
  pass=false
else
  phase=$(kubectl -n "$NS" get pvc "$PVC" -o jsonpath='{.status.phase}')
  if [ "$phase" != "Bound" ]; then
    msg+=("PVC '$PVC' not Bound (phase=$phase)")
    pass=false
  fi
fi

if ! kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1; then
  msg+=("Pod '$POD' missing")
  pass=false
else
  ready=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.status.containerStatuses[0].ready}')
  if [ "$ready" != "true" ]; then
    msg+=("Pod '$POD' not Ready")
    pass=false
  fi
  # Check mount path
  mount=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[0].volumeMounts[0].mountPath}')
  if [ "$mount" != "/data" ]; then
    msg+=("Pod '$POD' not mounting /data (mountPath=$mount)")
    pass=false
  fi
  # Check file content
  if ! kubectl -n "$NS" exec "$POD" -- sh -c 'test -f /data/ready.txt && grep -qx OK /data/ready.txt'; then
    msg+=("/data/ready.txt missing or content not OK")
    pass=false
  fi
fi

if $pass; then
  echo "PASS: storage-basic"
  exit 0
else
  echo "FAIL: storage-basic -> ${msg[*]}"
  exit 1
fi
