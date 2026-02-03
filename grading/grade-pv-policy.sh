#!/usr/bin/env bash
set -euo pipefail
NS="pv-chal"

pass=true
msg=()

# Check PV with Retain policy
if ! kubectl get pv pv-retain >/dev/null 2>&1; then
  msg+=("PV 'pv-retain' missing")
  pass=false
else
  policy=$(kubectl get pv pv-retain -o jsonpath='{.spec.persistentVolumeReclaimPolicy}')
  if [ "$policy" != "Retain" ]; then
    msg+=("PV 'pv-retain' does not have Retain policy (has $policy)")
    pass=false
  fi
fi

# Check PV with Delete policy
if ! kubectl get pv pv-delete >/dev/null 2>&1; then
  msg+=("PV 'pv-delete' missing")
  pass=false
else
  policy=$(kubectl get pv pv-delete -o jsonpath='{.spec.persistentVolumeReclaimPolicy}')
  if [ "$policy" != "Delete" ]; then
    msg+=("PV 'pv-delete' does not have Delete policy (has $policy)")
    pass=false
  fi
fi

# Check PVCs are bound
for pvc in pvc-retain pvc-delete; do
  if ! kubectl -n "$NS" get pvc "$pvc" >/dev/null 2>&1; then
    msg+=("PVC '$pvc' missing")
    pass=false
  else
    phase=$(kubectl -n "$NS" get pvc "$pvc" -o jsonpath='{.status.phase}')
    if [ "$phase" != "Bound" ]; then
      msg+=("PVC '$pvc' not Bound (phase=$phase)")
      pass=false
    fi
  fi
done

# Check pv-existing has Retain policy
if kubectl get pv pv-existing >/dev/null 2>&1; then
  policy=$(kubectl get pv pv-existing -o jsonpath='{.spec.persistentVolumeReclaimPolicy}')
  if [ "$policy" != "Retain" ]; then
    msg+=("PV 'pv-existing' not changed to Retain (has $policy)")
    pass=false
  fi
fi

if $pass; then
  echo "PASS: pv-reclaim-policy"
  exit 0
else
  echo "FAIL: pv-reclaim-policy -> ${msg[*]}"
  exit 1
fi
