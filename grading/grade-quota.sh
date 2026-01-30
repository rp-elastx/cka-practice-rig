#!/usr/bin/env bash
set -euo pipefail
NS=${1:-default}

pass=true
msg=()

rq=$(kubectl -n "$NS" get resourcequota -o name | wc -l)
if [ "$rq" -lt 1 ]; then
  msg+=("no ResourceQuota found in '$NS'")
  pass=false
else
  # Check for requests limits
  json=$(kubectl -n "$NS" get resourcequota -o json)
  has_req=$(python3 - <<'PY'
import sys,json
j=json.load(sys.stdin)
for i in j['items']:
    h=i.get('status',{}).get('hard',{})
    for k in h:
        if 'requests.cpu' in k or 'requests.memory' in k:
            print('YES');sys.exit(0)
print('NO')
PY
  )
  if [ "$has_req" != "YES" ]; then
    msg+=("no requests cpu/memory defined in quota")
    pass=false
  fi
fi

if $pass; then
  echo "PASS: quota"
  exit 0
else
  echo "FAIL: quota -> ${msg[*]}"
  exit 1
fi
