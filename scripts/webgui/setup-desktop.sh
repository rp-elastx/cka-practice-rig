#!/usr/bin/env bash
set -euo pipefail
# Deploy a browser-based desktop (linuxserver/webtop) proxied behind nginx at /desktop
# Uses host networking for direct access to kind clusters on localhost
# Mounts static kubectl binary (Alpine-compatible) for container use

REPO_DIR=$(cd "$(dirname "$0")/../.." && pwd)

# Ensure squid proxy exists (optional, may fail)
bash "$(dirname "$0")/setup-docs-proxy.sh" || echo "[desktop] Warning: docs proxy setup failed (non-critical)"

HOST_IP=$(hostname -I | awk '{print $1}')
SRC_KCFG="$REPO_DIR/kubeconfigs/merged.yaml"

# Use static kubectl binary (works in Alpine/musl containers)
# Fall back to regular kubectl if static not available
KUBECTL_STATIC="/usr/local/bin/kubectl-static"
if [ -f "$KUBECTL_STATIC" ]; then
  KUBECTL_BIN="$KUBECTL_STATIC"
else
  KUBECTL_BIN=$(command -v kubectl || true)
  if [ -z "$KUBECTL_BIN" ]; then
    for p in /usr/bin/kubectl /usr/local/bin/kubectl /snap/bin/kubectl; do
      [ -x "$p" ] && KUBECTL_BIN="$p" && break
    done
  fi
  echo "[desktop] Warning: static kubectl not found at $KUBECTL_STATIC; using $KUBECTL_BIN (may not work in Alpine)"
fi

# Determine cka user's UID/GID for proper file ownership
PUID=$(id -u cka 2>/dev/null || echo 1000)
PGID=$(id -g cka 2>/dev/null || echo 1000)

# Remove existing container
if docker ps -a --format '{{.Names}}' | grep -qx webtop; then
  echo "[desktop] Removing existing webtop container"
  docker rm -f webtop || true
fi

# Build volume mount arguments
MOUNTS=""
if [ -f "$SRC_KCFG" ]; then
  MOUNTS="$MOUNTS -v $SRC_KCFG:/config/.kube/config:ro"
fi
if [ -n "$KUBECTL_BIN" ] && [ -f "$KUBECTL_BIN" ]; then
  MOUNTS="$MOUNTS -v $KUBECTL_BIN:/usr/local/bin/kubectl:ro"
fi

echo "[desktop] Starting webtop container with host networking..."
docker run -d \
  --name webtop \
  --network host \
  -e PUID=$PUID -e PGID=$PGID \
  -e TZ=UTC \
  -e CUSTOM_PORT=3000 \
  -e HTTP_PROXY=http://127.0.0.1:3128 \
  -e HTTPS_PROXY=http://127.0.0.1:3128 \
  -e NO_PROXY=localhost,127.0.0.1,$HOST_IP \
  --restart unless-stopped \
  $MOUNTS \
  lscr.io/linuxserver/webtop:alpine

# Wait for container to start
sleep 3

# Clean up desktop: hide unnecessary apps, keep only browser and terminal
echo "[desktop] Cleaning up desktop applications..."
docker exec webtop sh -c '
  mkdir -p /config/.local/share/applications
  # Hide all apps except browser and terminal
  for app in /usr/share/applications/*.desktop; do
    name=$(basename "$app")
    case "$name" in
      firefox.desktop|chromium.desktop|xfce4-terminal.desktop|thunar.desktop)
        # Keep these visible
        ;;
      *)
        # Hide by copying with NoDisplay=true
        if [ -f "$app" ]; then
          cp "$app" "/config/.local/share/applications/$name"
          echo "NoDisplay=true" >> "/config/.local/share/applications/$name"
        fi
        ;;
    esac
  done
' 2>/dev/null || echo "[desktop] Note: Could not clean up desktop apps (container may still be starting)"

# Install bash-completion in container for kubectl
echo "[desktop] Installing bash-completion in container..."
docker exec webtop sh -c '
  apk add --no-cache bash-completion 2>/dev/null || true
  # Set up bashrc for abc user
  cat >> /config/.bashrc << "BASHRC"

# Bash completion
if [ -f /etc/bash/bash_completion.sh ]; then
  . /etc/bash/bash_completion.sh
fi

# kubectl completion
if command -v kubectl &>/dev/null; then
  source <(kubectl completion bash)
  alias k=kubectl
  complete -o default -F __start_kubectl k
fi

# KUBECONFIG
export KUBECONFIG=/config/.kube/config
BASHRC
' 2>/dev/null || echo "[desktop] Note: Could not configure bash in container"

# Update nginx site to proxy /desktop (script will re-create and restart nginx)
bash "$(dirname "$0")/setup-web.sh"

BASE_PATH="/cka-training"
echo "[desktop] Web desktop available at https://$HOST_IP$BASE_PATH/desktop/ (auth: cka/cka)"
echo "[desktop] Using host networking - kubectl can access kind clusters on localhost"
if [ -f "$SRC_KCFG" ]; then
  echo "[desktop] Kubeconfig mounted at /config/.kube/config"
fi
