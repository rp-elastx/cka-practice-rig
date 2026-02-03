#!/usr/bin/env bash
set -euo pipefail
NS="resources-chal"

pass=true
msg=()

# Check resource-pod has limits
if ! kubectl -n "$NS" get pod resource-pod >/dev/null 2>&1; then
  msg+=("Pod 'resource-pod' missing")
  pass=false
else
  cpuLimit=$(kubectl -n "$NS" get pod resource-pod -o jsonpath='{.spec.containers[0].resources.limits.cpu}')
  memLimit=$(kubectl -n "$NS" get pod resource-pod -o jsonpath='{.spec.containers[0].resources.limits.memory}')
  if [ "$cpuLimit" != "200m" ]; then
    msg+=("Pod 'resource-pod' CPU limit not 200m (is $cpuLimit)")
    pass=false
  fi
  if [ "$memLimit" != "256Mi" ]; then
    msg+=("Pod 'resource-pod' memory limit not 256Mi (is $memLimit)")
    pass=false
  fi
fi

# Check LimitRange
if ! kubectl -n "$NS" get limitrange default-limits >/dev/null 2>&1; then
  msg+=("LimitRange 'default-limits' missing")
  pass=false
fi

# Check ResourceQuota
if ! kubectl -n "$NS" get resourcequota ns-quota >/dev/null 2>&1; then
  msg+=("ResourceQuota 'ns-quota' missing")
  pass=false
fi

# Check auto-limits pod got defaults
if kubectl -n "$NS" get pod auto-limits >/dev/null 2>&1; then
  cpuLimit=$(kubectl -n "$NS" get pod auto-limits -o jsonpath='{.spec.containers[0].resources.limits.cpu}')
  if [ -z "$cpuLimit" ]; then
    msg+=("Pod 'auto-limits' did not get default CPU limit from LimitRange")
    pass=false
  fi
fi

if $pass; then
  echo "PASS: pod-resource-limits"
  exit 0
else
  echo "FAIL: pod-resource-limits -> ${msg[*]}"
  exit 1
fi
