#!/usr/bin/env bash
set -euo pipefail

pass=true
msg=()

# Check upgrade plan file exists
if [ ! -f /tmp/upgrade-plan.txt ]; then
  msg+=("Upgrade plan file /tmp/upgrade-plan.txt not found")
  pass=false
else
  # Check for key upgrade steps
  if ! grep -qi "kubeadm upgrade plan" /tmp/upgrade-plan.txt; then
    msg+=("Missing 'kubeadm upgrade plan' step")
    pass=false
  fi
  if ! grep -qi "kubeadm upgrade apply" /tmp/upgrade-plan.txt; then
    msg+=("Missing 'kubeadm upgrade apply' step")
    pass=false
  fi
  if ! grep -qi "kubelet" /tmp/upgrade-plan.txt; then
    msg+=("Missing kubelet upgrade step")
    pass=false
  fi
fi

if $pass; then
  echo "PASS: upgrade-cluster"
  exit 0
else
  echo "FAIL: upgrade-cluster -> ${msg[*]}"
  exit 1
fi
