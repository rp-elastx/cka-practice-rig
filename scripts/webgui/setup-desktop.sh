#!/usr/bin/env bash
set -euo pipefail
# Deploy a browser-based desktop (linuxserver/webtop) proxied behind nginx at /desktop
# Configure it to use the local squid proxy for docs-only browsing

REPO_DIR=$(cd "$(dirname "$0")/../.." && pwd)

# Ensure squid proxy exists
"$(dirname "$0")/setup-docs-proxy.sh"

# Determine cka user's UID/GID for proper file ownership
PUID=$(id -u cka 2>/dev/null || echo 1000)
PGID=$(id -g cka 2>/dev/null || echo 1000)

# Pull and run webtop
if ! docker ps -a --format '{{.Names}}' | grep -qx webtop; then
  echo "[desktop] Starting webtop container"
  docker run -d \
    --name webtop \
    -e PUID=$PUID -e PGID=$PGID \
    -e TZ=UTC \
    -e HTTP_PROXY=http://127.0.0.1:3128 \
    -e HTTPS_PROXY=http://127.0.0.1:3128 \
    -e NO_PROXY=localhost,127.0.0.1 \
    -p 3000:3000 \
    --restart unless-stopped \
    lscr.io/linuxserver/webtop:latest
else
  echo "[desktop] webtop container already present; ensuring it's running"
  docker start webtop || true
fi

# Update nginx site to proxy /desktop (script will re-create and restart nginx)
"$(dirname "$0")/setup-web.sh"

echo "[desktop] Web desktop available at http://$(hostname -I | awk '{print $1}')/desktop (auth: cka/cka)."
