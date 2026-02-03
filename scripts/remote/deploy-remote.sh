#!/usr/bin/env bash
set -euo pipefail

# Deploy and fix web setup on a remote server via SSH.
# Requires: SSH access to a host with root privileges and the repo present.
# Usage:
#   SSH_HOST=your.server SSH_USER=root REMOTE_REPO_DIR=/path/to/repo \
#     bash cka/cka-practice-rig/scripts/remote/deploy-remote.sh

SSH_HOST=${SSH_HOST:-}
SSH_USER=${SSH_USER:-root}
REMOTE_REPO_DIR=${REMOTE_REPO_DIR:-}

if [[ -z "$SSH_HOST" || -z "$REMOTE_REPO_DIR" ]]; then
  echo "Usage: SSH_HOST=<host> [SSH_USER=root] REMOTE_REPO_DIR=<path> bash cka/cka-practice-rig/scripts/remote/deploy-remote.sh" >&2
  exit 1
fi

echo "[deploy-remote] Connecting to $SSH_USER@$SSH_HOST and applying web fixes in $REMOTE_REPO_DIR ..."

ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$SSH_USER@$SSH_HOST" "REMOTE_REPO_DIR='$REMOTE_REPO_DIR' bash -lc '
  set -euo pipefail
  cd "$REMOTE_REPO_DIR"
  # Generate self-signed SSL if script exists
  if [ -f cka/cka-practice-rig/scripts/webgui/setup-selfsigned-ssl.sh ]; then
    sudo bash cka/cka-practice-rig/scripts/webgui/setup-selfsigned-ssl.sh || true
  fi
  # Rebuild nginx site config with fixed SSL insertion
  sudo bash cka/cka-practice-rig/scripts/webgui/setup-web.sh
  sudo nginx -t
  sudo systemctl restart nginx
  # Ensure terminal service is up (ttyd)
  sudo systemctl enable --now ttyd@cka || true
  # Attempt desktop setup (idempotent)
  if [ -f cka/cka-practice-rig/scripts/webgui/setup-desktop.sh ]; then
    sudo bash cka/cka-practice-rig/scripts/webgui/setup-desktop.sh || true
  fi
  echo "[remote] Active listeners:"
  ss -tlnp | grep nginx || true
  echo "[remote] API status (HTTPS via localhost):"
  curl -sk https://127.0.0.1/cka-training/api/status || true
'"

echo "[deploy-remote] Done. If issues persist, check remote logs: 'journalctl -u nginx --no-pager' and 'journalctl -u ttyd@cka --no-pager'"
