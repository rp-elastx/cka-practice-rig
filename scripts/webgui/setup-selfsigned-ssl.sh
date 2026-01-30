#!/usr/bin/env bash
set -euo pipefail
# Configure self-signed HTTPS for nginx so desktop (webtop/noVNC) can run over HTTPS

SITE_CONF="/etc/nginx/sites-available/cka-practice"
CERT_DIR="/etc/ssl/certs"
KEY_DIR="/etc/ssl/private"
CERT_PATH="$CERT_DIR/cka-practice-selfsigned.crt"
KEY_PATH="$KEY_DIR/cka-practice-selfsigned.key"

if [ ! -f "$SITE_CONF" ]; then
  echo "Error: nginx site config not found at $SITE_CONF. Run scripts/webgui/setup-web.sh first." >&2
  exit 1
fi

# Generate self-signed cert if missing
if [ ! -f "$CERT_PATH" ] || [ ! -f "$KEY_PATH" ]; then
  sudo mkdir -p "$CERT_DIR" "$KEY_DIR"
  CN=$(hostname -f || hostname)
  echo "[ssl] Generating self-signed certificate for CN=$CN"
  sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$KEY_PATH" -out "$CERT_PATH" \
    -subj "/CN=$CN" >/dev/null 2>&1
  sudo chmod 600 "$KEY_PATH"
fi

# Inject HTTPS listen and cert paths into site config if not present
if ! grep -q "listen 443 ssl" "$SITE_CONF"; then
  echo "[ssl] Enabling HTTPS in nginx site config"
  sudo sed -i "s/^\s*listen 80;$/  listen 80;\n  listen 443 ssl;\n  ssl_certificate $CERT_PATH;\n  ssl_certificate_key $KEY_PATH;/" "$SITE_CONF"
fi

# Test and restart nginx
sudo nginx -t
sudo systemctl restart nginx

IP=$(hostname -I | awk '{print $1}')
BASE_PATH="/cka-training"
echo "[ssl] Self-signed HTTPS enabled. Access: https://$IP$BASE_PATH/desktop (you may need to accept the cert)."
