#!/usr/bin/env bash
set -euo pipefail

pass=true
msg=()

# Check output files exist
for f in /tmp/nodes-by-age.txt /tmp/pods-by-start.txt /tmp/web-pods.txt /tmp/node-ips.txt; do
  if [ ! -f "$f" ]; then
    msg+=("Output file '$f' not found")
    pass=false
  elif [ ! -s "$f" ]; then
    msg+=("Output file '$f' is empty")
    pass=false
  fi
done

# Verify node-ips.txt contains IP addresses
if [ -f /tmp/node-ips.txt ]; then
  if ! grep -qE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' /tmp/node-ips.txt; then
    msg+=("/tmp/node-ips.txt does not contain IP addresses")
    pass=false
  fi
fi

if $pass; then
  echo "PASS: jsonpath-sort-output"
  exit 0
else
  echo "FAIL: jsonpath-sort-output -> ${msg[*]}"
  exit 1
fi
