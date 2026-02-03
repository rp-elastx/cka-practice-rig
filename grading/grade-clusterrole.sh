#!/usr/bin/env bash
set -euo pipefail

pass=true
msg=()

# Check ClusterRole node-reader
if ! kubectl get clusterrole node-reader >/dev/null 2>&1; then
  msg+=("ClusterRole 'node-reader' missing")
  pass=false
else
  res=$(kubectl get clusterrole node-reader -o jsonpath='{.rules[0].resources[0]}')
  if [ "$res" != "nodes" ]; then
    msg+=("ClusterRole 'node-reader' does not target nodes")
    pass=false
  fi
fi

# Check ClusterRole pv-manager
if ! kubectl get clusterrole pv-manager >/dev/null 2>&1; then
  msg+=("ClusterRole 'pv-manager' missing")
  pass=false
fi

# Check ClusterRoleBinding monitor-nodes
if ! kubectl get clusterrolebinding monitor-nodes >/dev/null 2>&1; then
  msg+=("ClusterRoleBinding 'monitor-nodes' missing")
  pass=false
else
  subj=$(kubectl get clusterrolebinding monitor-nodes -o jsonpath='{.subjects[0].name}')
  if [ "$subj" != "monitoring" ]; then
    msg+=("ClusterRoleBinding 'monitor-nodes' does not bind ServiceAccount 'monitoring'")
    pass=false
  fi
fi

# Check ClusterRoleBinding storage-admin-pv
if ! kubectl get clusterrolebinding storage-admin-pv >/dev/null 2>&1; then
  msg+=("ClusterRoleBinding 'storage-admin-pv' missing")
  pass=false
fi

# Test auth can-i
if ! kubectl auth can-i list nodes --as system:serviceaccount:ops:monitoring 2>/dev/null | grep -q "yes"; then
  msg+=("ServiceAccount 'ops:monitoring' cannot list nodes")
  pass=false
fi

if $pass; then
  echo "PASS: cluster-role-binding"
  exit 0
else
  echo "FAIL: cluster-role-binding -> ${msg[*]}"
  exit 1
fi
