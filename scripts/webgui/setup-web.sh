#!/usr/bin/env bash
set -euo pipefail
REPO_DIR=$(cd "$(dirname "$0")/../.." && pwd)
SCORE_DIR="$REPO_DIR/scoreboard"
WWW_DIR="/var/www/cka-practice"
SITE_CONF="/etc/nginx/sites-available/cka-practice"
BASE_PATH="/cka-training"
SSL_CERT="/etc/ssl/certs/cka-practice-selfsigned.crt"
SSL_KEY="/etc/ssl/private/cka-practice-selfsigned.key"

# Nginx: serve scoreboard and proxy desktop + API under base path
# Note: Terminal is available inside the desktop environment, no separate ttyd needed
sudo mkdir -p "$WWW_DIR"
sudo rsync -a "$SCORE_DIR/" "$WWW_DIR/scoreboard/"

HTPASSWD="/etc/nginx/htpasswd-cka"
if [ ! -f "$HTPASSWD" ]; then
  echo "cka:$(openssl passwd -apr1 cka)" | sudo tee "$HTPASSWD" >/dev/null
fi

sudo tee "$SITE_CONF" >/dev/null <<EOF
server {
  listen 80;
  server_name _;

  # Scoreboard static files under base path
  location $BASE_PATH/scoreboard/ {
    alias $WWW_DIR/scoreboard/;
    autoindex off;
    auth_basic "CKA Practice";
    auth_basic_user_file $HTPASSWD;
  }

  # Session page
  location $BASE_PATH/session.html {
    alias $WWW_DIR/scoreboard/session.html;
    auth_basic "CKA Practice";
    auth_basic_user_file $HTPASSWD;
  }

  # Web desktop (webtop with browser + terminal)
  location $BASE_PATH/desktop/ {
    auth_basic "CKA Practice";
    auth_basic_user_file $HTPASSWD;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_pass http://127.0.0.1:3000/;
  }

  # Control API proxy - increased timeout for reset operation (~2 min)
  location $BASE_PATH/api/ {
    auth_basic "CKA Practice";
    auth_basic_user_file $HTPASSWD;
    proxy_http_version 1.1;
    proxy_pass http://127.0.0.1:5005/api/;
    proxy_read_timeout 300s;
    proxy_connect_timeout 300s;
    proxy_send_timeout 300s;
  }

  # Root of base path -> session page
  location = $BASE_PATH {
    return 302 $BASE_PATH/session.html;
  }
}
EOF

sudo ln -sf "$SITE_CONF" /etc/nginx/sites-enabled/cka-practice
sudo rm -f /etc/nginx/sites-enabled/default || true
sudo systemctl restart nginx

# Systemd service + timer to sync scoreboard from repo to web root
SYNC_SVC="/etc/systemd/system/cka-scoreboard-sync.service"
SYNC_TIMER="/etc/systemd/system/cka-scoreboard-sync.timer"
sudo tee "$SYNC_SVC" >/dev/null <<EOF
[Unit]
Description=CKA scoreboard sync
Wants=cka-scoreboard-sync.timer

[Service]
Type=oneshot
ExecStart=/usr/bin/rsync -a "$SCORE_DIR/" "$WWW_DIR/scoreboard/"

[Install]
WantedBy=multi-user.target
EOF

sudo tee "$SYNC_TIMER" >/dev/null <<'EOF'
[Unit]
Description=Run CKA scoreboard sync periodically

[Timer]
OnBootSec=30s
OnUnitActiveSec=30s
Unit=cka-scoreboard-sync.service

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now cka-scoreboard-sync.timer

# Control API service
CTRL_UNIT="/etc/systemd/system/cka-control.service"
sudo tee "$CTRL_UNIT" >/dev/null <<'EOF'
[Unit]
Description=CKA Control API
After=network.target

[Service]
User=cka
Group=cka
WorkingDirectory=/home/cka/cka-practice-rig
ExecStart=/usr/bin/python3 scripts/webgui/control_server.py
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now cka-control.service

echo "[webgui] Nginx configured. Access: http://$(hostname -I | awk '{print $1}')$BASE_PATH"
echo "[webgui] Desktop: $BASE_PATH/desktop, Terminal: $BASE_PATH/terminal, Scoreboard: $BASE_PATH/scoreboard"