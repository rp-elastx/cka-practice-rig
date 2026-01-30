#!/usr/bin/env bash
set -euo pipefail

# Install dependencies on Ubuntu 24.04 and set up the practice rig
# - Docker, kind, kubectl, Python3 + PyYAML
# - nginx and ttyd for web GUI
# - sandbox user 'cka' for web terminal

if ! command -v lsb_release >/dev/null 2>&1; then
  echo "[install] lsb_release not found; ensure Ubuntu 24.04 environment"
fi

sudo apt update
sudo apt install -y ca-certificates curl gnupg jq python3 python3-pip python3-flask nginx apache2-utils

# Docker Engine
if ! command -v docker >/dev/null 2>&1; then
  echo "[install] Installing Docker Engine"
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker "$USER" || true
fi

# kubectl
if ! command -v kubectl >/dev/null 2>&1; then
  echo "[install] Installing kubectl"
  KVER=$(curl -s https://dl.k8s.io/release/stable.txt)
  curl -fsSL https://dl.k8s.io/release/${KVER}/bin/linux/amd64/kubectl -o /tmp/kubectl
  sudo install /tmp/kubectl /usr/local/bin/kubectl
fi

# kind
if ! command -v kind >/dev/null 2>&1; then
  echo "[install] Installing kind"
  KIND_VER=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | jq -r .tag_name)
  curl -fsSL https://kind.sigs.k8s.io/dl/${KIND_VER}/kind-linux-amd64 -o /tmp/kind
  sudo install /tmp/kind /usr/local/bin/kind
fi

# Python dependencies
python3 -m pip install --user --upgrade pip
python3 -m pip install --user PyYAML

# Helm CLI
if ! command -v helm >/dev/null 2>&1; then
  echo "[install] Installing Helm"
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# ttyd (web terminal)
if ! command -v ttyd >/dev/null 2>&1; then
  echo "[install] Installing ttyd"
  sudo apt install -y ttyd || {
    echo "[install] ttyd apt install failed; please install manually or via snap"
  }
fi

# Create sandbox user 'cka'
if ! id cka >/dev/null 2>&1; then
  sudo useradd -m -s /bin/bash cka
  echo "cka:cka" | sudo chpasswd
fi

# Ensure repo is available for 'cka' user terminal
if [ ! -d "/home/cka/cka-practice-rig" ]; then
  echo "[install] Copying repo to /home/cka/cka-practice-rig"
  sudo rsync -a "$REPO_DIR/" "/home/cka/cka-practice-rig/"
  sudo chown -R cka:cka /home/cka/cka-practice-rig
fi

# Configure web GUI (ttyd + nginx)
"$(dirname "$0")/webgui/setup-web.sh"

# Enable docs-only desktop and web desktop by default
"$(dirname "$0")/webgui/setup-docs-proxy.sh" || true
"$(dirname "$0")/webgui/setup-desktop.sh" || true

# Create clusters and merge kubeconfigs
"$(dirname "$0")/setup.sh"

IP=$(hostname -I | awk '{print $1}')
read -r -p "Enter domain for HTTPS (optional): " DOMAIN || DOMAIN=""
if [ -n "$DOMAIN" ]; then
  echo "[install] Configuring TLS for $DOMAIN"
  "$(dirname "$0")/webgui/setup-ssl.sh" "$DOMAIN" || echo "[install] TLS setup failed; continuing with HTTP"
  BASE_URL="https://$DOMAIN/cka-training"
else
  BASE_URL="http://$IP/cka-training"
fi

echo "\n[install] Completed. You may need to log out/in for Docker group changes to take effect."
echo "[install] Access: $BASE_URL"
echo "[install] Desktop: $BASE_URL/desktop"
echo "[install] Session: $BASE_URL/session.html"
echo "[install] Scoreboard: $BASE_URL/scoreboard/"