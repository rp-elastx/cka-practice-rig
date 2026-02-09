# CKA Practice Rig

Self-hosted CKA practice platform with kind-based multi-cluster, randomized challenges, automated grading, time limits, and a scoreboard.

## Features
- Multiple kind clusters (cka-a, cka-b, cka-c) with merged kubeconfig
- 39 CKA-style challenges covering all exam domains
- Randomized target context per challenge with per-challenge and session timers
- Automated grading with scoreboard (JSON + HTML)
- Web-based desktop with browser and terminal (terminal shortcut on desktop)
- Session controls: Grade, Previous, Next, New Session, Reset
- Reset with visual progress overlay showing status messages
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
1. Install all dependencies (Docker, kind, kubectl, helm, nginx)
2. Create sandbox user 'cka'
3. Create three kind clusters with storage provisioner
4. Set up web GUI with self-signed SSL
5. Start all services (web desktop, control API)

## Access (after install)

| URL | Description |
|-----|-------------|
| `https://<ip>/` | Landing page (Start Training button) |
| `https://<ip>/cka-training/session.html` | Session page with embedded desktop |
| `https://<ip>/cka-training/scoreboard/` | Results scoreboard |

**Credentials:** `cka` / `cka`

> **Note:** Self-signed SSL certificate - browser will show security warning.

## Session Controls

| Button | Description |
|--------|-------------|
| **Start Session** | Begin a new 2-hour timed session with 10 random challenges |
| **Grade** | Submit and grade the current challenge |
| **Previous** | Go back to a previous challenge (disabled on first challenge) |
| **Next** | Skip to the next challenge without grading |
| **New Session** | Start a fresh session (only visible when no session active) |
| **Reset** | Delete and recreate all clusters (~3-4 minutes) |

For production use with a domain:
```bash
bash scripts/webgui/setup-ssl.sh yourdomain.com
```

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

### Via Web UI (Recommended)
Click the **Reset** button in the session page. A progress overlay will show status:
- Removing old clusters
- Cleaning up configs
- Creating clusters cka-a, cka-b, cka-c
- Installing storage provisioner
- Finalizing setup

### Via CLI
```bash
bash scripts/reset.sh
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
