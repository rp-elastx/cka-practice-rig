#!/usr/bin/env bash
set -euo pipefail
REPO_DIR=$(cd "$(dirname "$0")/../.." && pwd)
SCORE_DIR="$REPO_DIR/scoreboard"
WWW_DIR="/var/www/cka-practice"
SITE_CONF="/etc/nginx/sites-available/cka-practice"
BASE_PATH="/cka-training"

echo "[webgui] Setting up nginx..."

# Create web root and sync scoreboard files
sudo mkdir -p "$WWW_DIR/scoreboard"
sudo rsync -a "$SCORE_DIR/" "$WWW_DIR/scoreboard/"

# Create htpasswd file (user: cka, pass: cka)
HTPASSWD="/etc/nginx/htpasswd-cka"
if [ ! -f "$HTPASSWD" ]; then
  echo "[webgui] Creating htpasswd file (cka/cka)"
  echo "cka:$(openssl passwd -apr1 cka)" | sudo tee "$HTPASSWD" >/dev/null
fi

# Write nginx config (HTTP only - setup-selfsigned-ssl.sh or setup-ssl.sh adds HTTPS)
sudo tee "$SITE_CONF" >/dev/null <<EOF
server {
    listen 80;
    server_name _;

    # Landing page at root (no auth required)
    location = / {
        root $WWW_DIR/scoreboard;
        try_files /landing.html =404;
    }

    # Session page at root level (outside base path for cleaner URLs)
    location /session.html {
        alias $WWW_DIR/scoreboard/session.html;
        auth_basic "CKA Practice";
        auth_basic_user_file $HTPASSWD;
    }

    # Scoreboard static files
    location $BASE_PATH/scoreboard/ {
        alias $WWW_DIR/scoreboard/;
        autoindex off;
        auth_basic "CKA Practice";
        auth_basic_user_file $HTPASSWD;
    }

    # Session page (also under base path for compatibility)
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

# Enable site
sudo ln -sf "$SITE_CONF" /etc/nginx/sites-enabled/cka-practice
sudo rm -f /etc/nginx/sites-enabled/default || true

# Test and restart nginx
sudo nginx -t
sudo systemctl restart nginx

# Systemd service + timer to sync scoreboard from repo to web root
echo "[webgui] Setting up scoreboard sync timer..."
SYNC_SVC="/etc/systemd/system/cka-scoreboard-sync.service"
SYNC_TIMER="/etc/systemd/system/cka-scoreboard-sync.timer"

sudo tee "$SYNC_SVC" >/dev/null <<EOF
[Unit]
Description=CKA scoreboard sync
Wants=cka-scoreboard-sync.timer

[Service]
Type=oneshot
ExecStart=/usr/bin/rsync -a /home/cka/cka-practice-rig/scoreboard/ $WWW_DIR/scoreboard/

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
echo "[webgui] Setting up cka-control API service..."
CTRL_UNIT="/etc/systemd/system/cka-control.service"
sudo tee "$CTRL_UNIT" >/dev/null <<'EOF'
[Unit]
Description=CKA Control API
After=network.target docker.service

[Service]
User=cka
Group=cka
WorkingDirectory=/home/cka/cka-practice-rig
ExecStart=/usr/bin/python3 scripts/webgui/control_server.py
Restart=always
RestartSec=2
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now cka-control.service

IP=$(hostname -I | awk '{print $1}')
echo ""
echo "[webgui] ✓ Nginx configured!"
echo "[webgui] Access URLs (will need HTTPS after setup-selfsigned-ssl.sh):"
echo "  Landing:     http://$IP/"
echo "  Session:     http://$IP$BASE_PATH/session.html"
echo "  Desktop:     http://$IP$BASE_PATH/desktop/"
echo "  Scoreboard:  http://$IP$BASE_PATH/scoreboard/"
echo "  Credentials: cka / cka"
