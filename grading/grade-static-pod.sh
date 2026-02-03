#!/usr/bin/env bash
set -euo pipefail

pass=true
msg=()

# Check static pod exists
if ! kubectl get pod -A | grep -q "static-web"; then
  msg+=("Static pod 'static-web' not found")
  pass=false
fi

# Check output files
if [ ! -f /tmp/static-pods.txt ]; then
  msg+=("Output file /tmp/static-pods.txt not found")
  pass=false
fi

if [ ! -f /tmp/static-pod-path.txt ]; then
  msg+=("Output file /tmp/static-pod-path.txt not found")
  pass=false
elif ! grep -q "/etc/kubernetes/manifests" /tmp/static-pod-path.txt; then
  msg+=("/tmp/static-pod-path.txt does not contain correct manifest path")
  pass=false
fi

if $pass; then
  echo "PASS: static-pod"
  exit 0
else
  echo "FAIL: static-pod -> ${msg[*]}"
  exit 1
fi
