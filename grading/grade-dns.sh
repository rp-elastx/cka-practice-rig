#!/usr/bin/env bash
set -euo pipefail
NS="dns-chal"

pass=true
msg=()

# Check dns-test pod exists and is running
if ! kubectl -n "$NS" get pod dns-test >/dev/null 2>&1; then
  msg+=("Pod 'dns-test' missing")
  pass=false
else
  ready=$(kubectl -n "$NS" get pod dns-test -o jsonpath='{.status.phase}')
  if [ "$ready" != "Running" ]; then
    msg+=("Pod 'dns-test' not Running (is $ready)")
    pass=false
  fi
fi

# Check output files
if [ ! -f /tmp/dns-results.txt ]; then
  msg+=("Output file /tmp/dns-results.txt not found")
  pass=false
elif [ ! -s /tmp/dns-results.txt ]; then
  msg+=("/tmp/dns-results.txt is empty")
  pass=false
fi

if [ ! -f /tmp/dns-server.txt ]; then
  msg+=("Output file /tmp/dns-server.txt not found")
  pass=false
fi

if $pass; then
  echo "PASS: dns-troubleshooting"
  exit 0
else
  echo "FAIL: dns-troubleshooting -> ${msg[*]}"
  exit 1
fi
