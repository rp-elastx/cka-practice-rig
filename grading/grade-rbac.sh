#!/usr/bin/env bash
set -euo pipefail
NS="rbac-chal"
ROLE="pod-reader"
RB="read-pods"
USER="student"

pass=true
msg=()

if ! kubectl -n "$NS" get role "$ROLE" >/dev/null 2>&1; then
  msg+=("Role '$ROLE' missing")
  pass=false
else
  # Check rules
  res=$(kubectl -n "$NS" get role "$ROLE" -o jsonpath='{.rules[0].resources[0]}')
  verbs=$(kubectl -n "$NS" get role "$ROLE" -o jsonpath='{.rules[0].verbs}')
  if [ "$res" != "pods" ]; then
    msg+=("Role does not target pods")
    pass=false
  fi
  echo "$verbs" | grep -q "get" && echo "$verbs" | grep -q "list" && echo "$verbs" | grep -q "watch" || { msg+=("Role verbs not get/list/watch"); pass=false; }
fi

if ! kubectl -n "$NS" get rolebinding "$RB" >/dev/null 2>&1; then
  msg+=("RoleBinding '$RB' missing")
  pass=false
else
  subj_kind=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.subjects[0].kind}')
  subj_name=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.subjects[0].name}')
  role_ref=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.roleRef.name}')
  if [ "$subj_kind" != "User" ] || [ "$subj_name" != "$USER" ]; then
    msg+=("RoleBinding does not bind User '$USER'")
    pass=false
  fi
  if [ "$role_ref" != "$ROLE" ]; then
    msg+=("RoleBinding does not reference Role '$ROLE'")
    pass=false
  fi
fi

if $pass; then
  echo "PASS: rbac-rolebinding"
  exit 0
else
  echo "FAIL: rbac-rolebinding -> ${msg[*]}"
  exit 1
fi
