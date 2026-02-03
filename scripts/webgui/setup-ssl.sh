#!/usr/bin/env bash
set -euo pipefail
# Configure HTTPS for nginx using certbot and set domain server_name
# Usage: bash scripts/webgui/setup-ssl.sh vanskapt.se

DOMAIN=${1:-}
if [ -z "$DOMAIN" ]; then
  echo "Usage: $0 <domain>" >&2
  exit 1
fi

# Install certbot via snap (recommended on Ubuntu 24.04)
if ! command -v certbot >/dev/null 2>&1; then
  sudo snap install core
  sudo snap refresh core
  sudo snap install --classic certbot
  sudo ln -sf /snap/bin/certbot /usr/bin/certbot
fi

SITE_CONF="/etc/nginx/sites-available/cka-practice"
if [ ! -f "$SITE_CONF" ]; then
  echo "Error: nginx site config not found at $SITE_CONF. Run scripts/webgui/setup-web.sh first." >&2
  exit 1
fi

# Update server_name to the given domain
sudo sed -i "s/server_name _;/server_name $DOMAIN;/" "$SITE_CONF"

# Reload nginx to ensure config parse OK
sudo nginx -t
sudo systemctl reload nginx

# Obtain and install certificate (nginx plugin)
sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m admin@"$DOMAIN" || {
  echo "[ssl] certbot failed; check DNS and port 80 reachability." >&2
  exit 1
}

# Redirect HTTP to HTTPS (certbot typically adds ssl_server blocks)
# Ensure site enabled
sudo ln -sf "$SITE_CONF" /etc/nginx/sites-enabled/cka-practice
sudo systemctl restart nginx

echo "[ssl] HTTPS configured for https://$DOMAIN/cka-training"
