#!/usr/bin/env bash
set -euo pipefail
# Install and configure a restrictive HTTP(S) proxy to allow only Kubernetes docs domains

# Disable stale Kubernetes apt source if present to avoid update failures
if [ -f "/etc/apt/sources.list.d/kubernetes.list" ]; then
	sudo mv /etc/apt/sources.list.d/kubernetes.list /etc/apt/sources.list.d/kubernetes.list.disabled || true
fi

sudo apt-get update -y
sudo apt-get install -y squid

SQUID_CONF="/etc/squid/squid.conf"

# Backup original
sudo cp -n "$SQUID_CONF" "/etc/squid/squid.conf.bak"

# Minimal restrictive config
sudo tee "$SQUID_CONF" >/dev/null <<'EOF'
# Squid restrictive proxy for CKA docs
http_port 3128

# ACLs for allowed destinations
acl allowed_sites dstdomain kubernetes.io docs.kubernetes.io

# SSL bump/SNI is complex; keep simple and rely on CONNECT with dstdomain ACL
acl SSL_ports port 443
acl Safe_ports port 80 443 1025-65535
acl CONNECT method CONNECT

# Default deny
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports

# Allow only allowed_sites
http_access allow allowed_sites
http_access deny all

# Logging
access_log daemon:/var/log/squid/access.log
cache_log /var/log/squid/cache.log
cache_store_log none

# Performance tweaks
via off
forwarded_for off
EOF

sudo systemctl restart squid || true

# Show status
sudo systemctl --no-pager status squid || true

echo "[docs-proxy] Squid configured. HTTP(S) proxy at http://127.0.0.1:3128 allowing only kubernetes.io and docs.kubernetes.io."
