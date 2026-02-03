#!/usr/bin/env bash
set -euo pipefail

echo "[setup-etcd] etcd backup/restore challenge ready."
echo "Use etcdctl to backup etcd to /tmp/etcd-backup.db"
echo "Certificates are in /etc/kubernetes/pki/etcd/"
