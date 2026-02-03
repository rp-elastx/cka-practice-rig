#!/usr/bin/env bash
set -euo pipefail
NS="deploy-chal"
DEPLOY="web"
HPA="$DEPLOY"

pass=true
msg=()

if ! kubectl -n "$NS" get deploy "$DEPLOY" >/dev/null 2>&1; then
  msg+=("Deployment '$DEPLOY' missing in '$NS'")
  pass=false
else
  # Check CPU requests exist
  req=$(kubectl -n "$NS" get deploy "$DEPLOY" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}') || req=""
  if [ -z "$req" ]; then
    msg+=("CPU request missing on container")
    pass=false
  fi
fi

# Check HPA exists and properties
if ! kubectl -n "$NS" get hpa "$HPA" >/dev/null 2>&1; then
  msg+=("HPA '$HPA' missing in '$NS'")
  pass=false
else
  min=$(kubectl -n "$NS" get hpa "$HPA" -o jsonpath='{.spec.minReplicas}')
  max=$(kubectl -n "$NS" get hpa "$HPA" -o jsonpath='{.spec.maxReplicas}')
  target=$(kubectl -n "$NS" get hpa "$HPA" -o jsonpath='{.spec.metrics[0].resource.target.averageUtilization}')
  stab=$(kubectl -n "$NS" get hpa "$HPA" -o jsonpath='{.spec.behavior.scaleDown.stabilizationWindowSeconds}')
  [ "$min" = "1" ] || { msg+=("minReplicas != 1 (got $min)"); pass=false; }
  [ "$max" = "4" ] || { msg+=("maxReplicas != 4 (got $max)"); pass=false; }
  [ "$target" = "50" ] || { msg+=("averageUtilization != 50 (got $target)"); pass=false; }
  [ "$stab" = "30" ] || { msg+=("scaleDown.stabilizationWindowSeconds != 30 (got $stab)"); pass=false; }
fi

if $pass; then
  echo "PASS: deployment-scale"
  exit 0
else
  echo "FAIL: deployment-scale -> ${msg[*]}"
  exit 1
fi
