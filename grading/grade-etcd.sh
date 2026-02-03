#!/usr/bin/env bash
set -euo pipefail

pass=true
msg=()

# Check backup file exists
if [ ! -f /tmp/etcd-backup.db ]; then
  msg+=("Backup file /tmp/etcd-backup.db not found")
  pass=false
else
  # Verify it's a valid etcd snapshot
  if ! file /tmp/etcd-backup.db | grep -q "data"; then
    msg+=("Backup file doesn't appear to be valid")
    pass=false
  fi
fi

# Check restored directory exists
if [ ! -d /var/lib/etcd-restored ]; then
  msg+=("Restored directory /var/lib/etcd-restored not found")
  pass=false
fi

if $pass; then
  echo "PASS: etcd-backup-restore"
  exit 0
else
  echo "FAIL: etcd-backup-restore -> ${msg[*]}"
  exit 1
fi
