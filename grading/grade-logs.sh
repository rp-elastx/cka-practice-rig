#!/usr/bin/env bash
set -euo pipefail

pass=true
msg=()

# Check output files exist
for f in /tmp/restart-pods.txt /tmp/nginx-logs.txt /tmp/previous-logs.txt /tmp/warning-events.txt /tmp/top-cpu-pod.txt; do
  if [ ! -f "$f" ]; then
    msg+=("Output file '$f' not found")
    pass=false
  fi
done

# Verify nginx-logs has content
if [ -f /tmp/nginx-logs.txt ] && [ ! -s /tmp/nginx-logs.txt ]; then
  msg+=("/tmp/nginx-logs.txt is empty")
  pass=false
fi

if $pass; then
  echo "PASS: pod-logs-events"
  exit 0
else
  echo "FAIL: pod-logs-events -> ${msg[*]}"
  exit 1
fi
