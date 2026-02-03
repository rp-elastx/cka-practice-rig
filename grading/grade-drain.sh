#!/usr/bin/env bash
set -euo pipefail

pass=true
msg=()

# Get worker node name
WORKER=$(kubectl get nodes -o jsonpath='{.items[?(@.metadata.labels.node-role\.kubernetes\.io/control-plane!="")].metadata.name}' | head -1)
if [ -z "$WORKER" ]; then
  WORKER=$(kubectl get nodes --no-headers | grep -v control-plane | awk '{print $1}' | head -1)
fi

if [ -z "$WORKER" ]; then
  msg+=("Could not find worker node")
  pass=false
else
  # Check node is Ready and schedulable
  status=$(kubectl get node "$WORKER" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
  schedulable=$(kubectl get node "$WORKER" -o jsonpath='{.spec.unschedulable}')
  
  if [ "$status" != "True" ]; then
    msg+=("Node '$WORKER' is not Ready")
    pass=false
  fi
  
  if [ "$schedulable" == "true" ]; then
    msg+=("Node '$WORKER' is still unschedulable (not uncordoned)")
    pass=false
  fi
fi

if $pass; then
  echo "PASS: node-drain-cordon"
  exit 0
else
  echo "FAIL: node-drain-cordon -> ${msg[*]}"
  exit 1
fi
