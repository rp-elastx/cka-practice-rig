#!/usr/bin/env bash
set -euo pipefail
# Deploy a browser-based desktop (linuxserver/webtop) proxied behind nginx at /desktop
# Configure it to use the local squid proxy for docs-only browsing

REPO_DIR=$(cd "$(dirname "$0")/../.." && pwd)

# Ensure squid proxy exists
bash "$(dirname "$0")/setup-docs-proxy.sh"

# Prepare kubeconfig usable from inside container (replace 127.0.0.1 with host IP)
HOST_IP=$(hostname -I | awk '{print $1}')
SRC_KCFG="$REPO_DIR/kubeconfigs/merged.yaml"
DST_KCFG="$REPO_DIR/kubeconfigs/merged-desktop.yaml"
if [ -f "$SRC_KCFG" ]; then
  sed "s#https://127.0.0.1:#https://$HOST_IP:#g" "$SRC_KCFG" > "$DST_KCFG"
else
  echo "[desktop] Warning: kubeconfig not found at $SRC_KCFG; desktop will start without cluster access"
fi

# Resolve host kubectl and mount into container
KUBECTL_BIN=$(command -v kubectl || true)
if [ -z "$KUBECTL_BIN" ]; then
  for p in /usr/bin/kubectl /usr/local/bin/kubectl /snap/bin/kubectl; do
    [ -x "$p" ] && KUBECTL_BIN="$p" && break
  done
fi

# Determine cka user's UID/GID for proper file ownership
PUID=$(id -u cka 2>/dev/null || echo 1000)
PGID=$(id -g cka 2>/dev/null || echo 1000)

# Pull and run webtop
if docker ps -a --format '{{.Names}}' | grep -qx webtop; then
  echo "[desktop] Recreating webtop container to apply mounts"
  docker rm -f webtop || true
fi
echo "[desktop] Starting webtop container"
docker run -d \
  --name webtop \
  -e PUID=$PUID -e PGID=$PGID \
  -e TZ=UTC \
  -e HTTP_PROXY=http://127.0.0.1:3128 \
  -e HTTPS_PROXY=http://127.0.0.1:3128 \
  -e NO_PROXY=localhost,127.0.0.1,$HOST_IP \
  -p 3000:3000 \
  --restart unless-stopped \
  $( [ -f "$DST_KCFG" ] && echo -v "$DST_KCFG:/config/.kube/config:ro" ) \
  $( [ -n "$KUBECTL_BIN" ] && echo -v "$KUBECTL_BIN:/usr/local/bin/kubectl:ro" ) \
  lscr.io/linuxserver/webtop:latest

# Update nginx site to proxy /desktop (script will re-create and restart nginx)
bash "$(dirname "$0")/setup-web.sh"

BASE_PATH="/cka-training"
echo "[desktop] Web desktop available at http://$(hostname -I | awk '{print $1}')$BASE_PATH/desktop (auth: cka/cka)."
if [ -f "$DST_KCFG" ]; then
  echo "[desktop] Inside desktop, kubectl will use kubeconfig at /config/.kube/config (mounted from host)."
fi
