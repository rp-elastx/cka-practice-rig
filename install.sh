#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# CKA Practice Rig - One-Command Installer for Ubuntu 24.04
###############################################################################
# Usage:
#   git clone https://github.com/rp-elastx/cka-practice-rig.git
#   cd cka-practice-rig
#   ./install.sh
#
# This script will:
#   1. Install all dependencies (Docker, kind, kubectl, helm, python3, nginx)
#   2. Create sandbox user 'cka'
#   3. Create three kind clusters (cka-a, cka-b, cka-c) with storage provisioner
#   4. Set up web GUI with nginx (scoreboard, desktop)
#   5. Generate self-signed SSL certificate for HTTPS
#   6. Start all services (control API, desktop container)
#
# After installation, access at: https://<server-ip>/cka-training (user: cka, pass: cka)
###############################################################################

REPO_DIR=$(cd "$(dirname "$0")" && pwd)
LOG_FILE="$REPO_DIR/install.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[install]${NC} $*"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[install]${NC} WARNING: $*"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $*" >> "$LOG_FILE"; }
error() { echo -e "${RED}[install]${NC} ERROR: $*"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >> "$LOG_FILE"; }

check_ubuntu() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" != "ubuntu" ]; then
      warn "This script is designed for Ubuntu. Detected: $ID"
    fi
    log "Detected OS: $PRETTY_NAME"
  else
    warn "Cannot detect OS version"
  fi
}

install_base_packages() {
  log "Installing base packages..."
  sudo apt-get update -y
  sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    jq \
    python3 \
    python3-pip \
    python3-venv \
    nginx \
    apache2-utils \
    rsync \
    git \
    openssl
}

install_docker() {
  if command -v docker &>/dev/null; then
    log "Docker already installed: $(docker --version)"
    return
  fi

  log "Installing Docker Engine..."
  
  # Set up Docker's apt repository
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $CODENAME stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  if sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
    log "Docker CE installed successfully"
  else
    warn "Docker CE install failed, falling back to docker.io"
    sudo apt-get install -y docker.io
  fi

  # Add current user to docker group
  sudo usermod -aG docker "$USER" || true
  
  # Start and enable docker
  sudo systemctl enable --now docker
  
  log "Docker installed: $(docker --version)"
}

install_kubectl() {
  if command -v kubectl &>/dev/null; then
    log "kubectl already installed: $(kubectl version --client --short 2>/dev/null || echo 'ok')"
    return
  fi

  log "Installing kubectl..."
  
  # Try snap first (most reliable on Ubuntu)
  if command -v snap &>/dev/null; then
    if sudo snap install kubectl --classic; then
      log "kubectl installed via snap"
      return
    fi
  fi

  # Direct download as fallback
  log "Installing kubectl via direct download..."
  KVER=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
  if [[ "$KVER" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    curl -fsSL "https://dl.k8s.io/release/${KVER}/bin/linux/amd64/kubectl" -o /tmp/kubectl
    sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
    rm -f /tmp/kubectl
    log "kubectl installed: $(kubectl version --client --short 2>/dev/null || echo 'ok')"
  else
    error "Failed to determine kubectl version"
    exit 1
  fi
}

install_kind() {
  if command -v kind &>/dev/null; then
    log "kind already installed: $(kind version)"
    return
  fi

  log "Installing kind..."
  KIND_VER=$(curl -fsSL https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | jq -r .tag_name)
  curl -fsSL "https://kind.sigs.k8s.io/dl/${KIND_VER}/kind-linux-amd64" -o /tmp/kind
  sudo install -o root -g root -m 0755 /tmp/kind /usr/local/bin/kind
  rm -f /tmp/kind
  log "kind installed: $(kind version)"
}

install_helm() {
  if command -v helm &>/dev/null; then
    log "Helm already installed: $(helm version --short)"
    return
  fi

  log "Installing Helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  log "Helm installed: $(helm version --short)"
}

install_python_deps() {
  log "Installing Python dependencies..."
  # Use venv to avoid pip externally-managed-environment error on Ubuntu 24.04
  VENV_DIR="$REPO_DIR/.venv"
  if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
  fi
  "$VENV_DIR/bin/pip" install --upgrade pip
  "$VENV_DIR/bin/pip" install flask PyYAML
  
  # Also install system-wide for the cka user's control server
  sudo apt-get install -y python3-flask python3-yaml || true
}

create_cka_user() {
  if id cka &>/dev/null; then
    log "User 'cka' already exists"
  else
    log "Creating sandbox user 'cka'..."
    sudo useradd -m -s /bin/bash cka
    echo "cka:cka" | sudo chpasswd
  fi

  # Add cka user to docker group
  sudo usermod -aG docker cka || true

  # Copy repo to cka's home
  log "Syncing repository to /home/cka/cka-practice-rig..."
  sudo rsync -a --delete "$REPO_DIR/" /home/cka/cka-practice-rig/
  sudo chown -R cka:cka /home/cka/cka-practice-rig
  
  # Set up bash completion for kubectl in cka's bashrc
  CKA_BASHRC="/home/cka/.bashrc"
  if ! sudo grep -q "kubectl completion" "$CKA_BASHRC" 2>/dev/null; then
    sudo tee -a "$CKA_BASHRC" >/dev/null <<'EOF'

# kubectl completion
source <(kubectl completion bash)
alias k=kubectl
complete -o default -F __start_kubectl k

# KUBECONFIG
export KUBECONFIG=~/cka-practice-rig/kubeconfigs/merged.yaml
EOF
    sudo chown cka:cka "$CKA_BASHRC"
  fi
}

fix_hostname_resolution() {
  HOSTNAME_CURRENT=$(hostname)
  if ! grep -q "\b$HOSTNAME_CURRENT\b" /etc/hosts; then
    log "Adding hostname '$HOSTNAME_CURRENT' to /etc/hosts"
    echo "127.0.1.1 $HOSTNAME_CURRENT" | sudo tee -a /etc/hosts >/dev/null
  fi
}

create_clusters() {
  log "Creating kind clusters (cka-a, cka-b, cka-c)..."
  bash "$REPO_DIR/scripts/setup.sh"
}

setup_webgui() {
  log "Setting up web GUI (nginx, desktop)..."
  
  # Setup web (nginx config)
  bash "$REPO_DIR/scripts/webgui/setup-web.sh"
  
  # Setup self-signed SSL
  log "Generating self-signed SSL certificate..."
  bash "$REPO_DIR/scripts/webgui/setup-selfsigned-ssl.sh"
  
  # Setup docs proxy (squid) - optional, may fail
  log "Setting up docs proxy..."
  bash "$REPO_DIR/scripts/webgui/setup-docs-proxy.sh" || warn "Docs proxy setup failed (non-critical)"
  
  # Setup desktop container
  log "Setting up web desktop..."
  bash "$REPO_DIR/scripts/webgui/setup-desktop.sh" || warn "Desktop setup failed (non-critical)"
}

setup_static_kubectl() {
  # Download a static kubectl for use inside Alpine-based containers
  STATIC_KUBECTL="/usr/local/bin/kubectl-static"
  if [ ! -f "$STATIC_KUBECTL" ]; then
    log "Downloading static kubectl binary for containers..."
    KVER=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
    curl -fsSL "https://dl.k8s.io/release/${KVER}/bin/linux/amd64/kubectl" -o /tmp/kubectl-static
    sudo install -o root -g root -m 0755 /tmp/kubectl-static "$STATIC_KUBECTL"
    rm -f /tmp/kubectl-static
  fi
}

sync_cka_repo() {
  # Final sync to ensure cka user has latest
  log "Final sync to /home/cka/cka-practice-rig..."
  sudo rsync -a --delete "$REPO_DIR/" /home/cka/cka-practice-rig/
  sudo chown -R cka:cka /home/cka/cka-practice-rig
  
  # Copy kubeconfigs
  if [ -d "$REPO_DIR/kubeconfigs" ]; then
    sudo cp -r "$REPO_DIR/kubeconfigs" /home/cka/cka-practice-rig/
    sudo chown -R cka:cka /home/cka/cka-practice-rig/kubeconfigs
  fi
}

restart_services() {
  log "Restarting services..."
  sudo systemctl daemon-reload
  sudo systemctl restart nginx || warn "nginx restart failed"
  sudo systemctl restart cka-control || warn "cka-control restart failed"
  sudo systemctl restart cka-scoreboard-sync.timer || warn "scoreboard sync timer restart failed"
}

print_summary() {
  IP=$(hostname -I | awk '{print $1}')
  echo ""
  echo "============================================================"
  echo -e "${GREEN}CKA Practice Rig Installation Complete!${NC}"
  echo "============================================================"
  echo ""
  echo "Access URLs (credentials: cka / cka):"
  echo "  Session Page: https://$IP/cka-training/session.html"
  echo "  Web Desktop:  https://$IP/cka-training/desktop/"
  echo "  Web Terminal: https://$IP/cka-training/terminal/"
  echo "  Scoreboard:   https://$IP/cka-training/scoreboard/"
  echo ""
  echo "Note: Using self-signed SSL certificate - browser will show warning."
  echo ""
  echo "Clusters created:"
  kind get clusters 2>/dev/null | sed 's/^/  - /'
  echo ""
  echo "To reset and recreate clusters:"
  echo "  cd /home/cka/cka-practice-rig && ./scripts/reset.sh && ./scripts/setup.sh"
  echo ""
  echo "Log file: $LOG_FILE"
  echo "============================================================"
}

# Ensure we can use docker immediately (for kind cluster creation)
ensure_docker_access() {
  if ! docker info &>/dev/null; then
    warn "Docker not accessible. Trying with newgrp..."
    # Can't use newgrp in script, so we'll use sudo for docker commands
    if sudo docker info &>/dev/null; then
      log "Docker accessible via sudo - will use sudo for initial setup"
      # Symlink docker to use sudo
      export DOCKER_HOST=unix:///var/run/docker.sock
    else
      error "Docker not accessible. Please log out and back in, then re-run ./install.sh"
      exit 1
    fi
  fi
}

main() {
  echo ""
  echo "============================================================"
  echo "CKA Practice Rig Installer"
  echo "============================================================"
  echo ""
  
  # Initialize log
  echo "Installation started at $(date)" > "$LOG_FILE"
  
  check_ubuntu
  install_base_packages
  install_docker
  ensure_docker_access
  install_kubectl
  install_kind
  install_helm
  install_python_deps
  fix_hostname_resolution
  create_cka_user
  setup_static_kubectl
  create_clusters
  setup_webgui
  sync_cka_repo
  restart_services
  print_summary
}

# Run main
main "$@"
