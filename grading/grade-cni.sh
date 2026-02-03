#!/usr/bin/env bash
set -euo pipefail
# Validate CNI daemonset exists (kindnet, calico, or cilium) in kube-system

pass=true
msg=()

names=$(kubectl -n kube-system get ds -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
if echo "$names" | grep -Eq 'kindnet|calico|cilium'; then
  :
else
  msg+=("no known CNI daemonset found (kindnet/calico/cilium)")
  pass=false
fi

if $pass; then
  echo "PASS: cni"
  exit 0
else
  echo "FAIL: cni -> ${msg[*]}"
  exit 1
fi
