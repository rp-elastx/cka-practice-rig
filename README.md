# CKA Practice Rig

Self-hosted CKA practice platform with kind-based multi-cluster, randomized challenges, automated grading, time limits, and a scoreboard.

## Features
- Multiple kind clusters (cka-a, cka-b, cka-c) with merged kubeconfig
- 39 CKA-style challenges covering all exam domains
- Randomized target context per challenge with per-challenge and session timers
- Automated grading with scoreboard (JSON + HTML)
- Web-based desktop and terminal access
- Resettable environment via web controls or CLI

## Quick Install (Ubuntu 24.04)

```bash
# Clone the repository
git clone https://github.com/rp-elastx/cka-practice-rig.git
cd cka-practice-rig

# Run the installer (takes ~10-15 minutes)
./install.sh
```

The installer will:
1. Install all dependencies (Docker, kind, kubectl, helm, nginx, ttyd)
2. Create sandbox user 'cka' for web terminal
3. Create three kind clusters with storage provisioner
4. Set up web GUI with self-signed SSL
5. Start all services

## Access (after install)

| URL | Description |
|-----|-------------|
| `https://<ip>/cka-training/session.html` | Main session page |
| `https://<ip>/cka-training/desktop/` | Web desktop (browser + terminal) |
| `https://<ip>/cka-training/terminal/` | Web terminal only |
| `https://<ip>/cka-training/scoreboard/` | Results scoreboard |

**Credentials:** `cka` / `cka`

> **Note:** Self-signed SSL certificate - browser will show security warning.

## Change Passwords (Recommended)

```bash
# Web auth (nginx basic auth)
sudo htpasswd /etc/nginx/htpasswd-cka cka
sudo systemctl reload nginx

# System user 'cka'
sudo passwd cka
```

## Manual Setup (Advanced)

If you prefer step-by-step control:

```bash
# 1. Install dependencies only
bash scripts/install.sh --deps-only  # (or run individual sections)

# 2. Create clusters
bash scripts/setup.sh

# 3. Set up web GUI
bash scripts/webgui/setup-web.sh
bash scripts/webgui/setup-selfsigned-ssl.sh
bash scripts/webgui/setup-desktop.sh

# 4. (Optional) Set up Let's Encrypt SSL with domain
bash scripts/webgui/setup-ssl.sh your-domain.com
```

## Reset Environment

```bash
# Delete clusters and recreate fresh
bash scripts/reset.sh
bash scripts/setup.sh
```

## Challenge Categories

| Category | Count | Topics |
|----------|-------|--------|
| Cluster Architecture | 4 | etcd backup, node drain, upgrade, static pods |
| RBAC | 4 | Roles, ClusterRoles, ServiceAccounts |
| Workloads | 8 | Deployments, rollouts, multi-container pods, resources |
| Scheduling | 3 | Affinity, taints, tolerations |
| Storage | 4 | PV, PVC, StorageClass, reclaim policies |
| Networking | 5 | Services, DNS, NetworkPolicy, Ingress |
| Troubleshooting | 6 | Logs, events, JSONPath, cluster issues |
| Helm | 2 | Install, templating, custom values |
| Gateway API | 2 | Migration, configuration |

## Notes
- Each challenge specifies its target cluster and namespace
- Work only in the specified namespace unless stated otherwise
- Submissions after time limit are marked but grading continues
- Use `kubectl config use-context` to switch between clusters
