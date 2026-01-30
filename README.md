# CKA Practice Rig

Self-hosted CKA practice platform with kind-based multi-cluster, randomized challenges, automated grading, time limits, and a scoreboard.

## Features
- Multiple kind clusters and merged kubeconfig with distinct contexts
- Ready‑made baseline challenges (6) plus imported challenge specs (15) mapped to categories
- Randomized target context per challenge with per‑challenge and session timers
- Automated grading with a simple scoreboard (JSON + HTML)
- Resettable environment via web controls or script

## Prerequisites
- Ubuntu 24.04 (recommended) with Bash. The installer will install Docker, kind, kubectl, Python 3, nginx, Squid, ttyd, and Helm.

## Quickstart
```bash
# 1) Install everything: web GUI (desktop + terminal + docs proxy) and clusters
bash scripts/install.sh

# 2) Change passwords (recommended)
# Web auth (nginx basic auth for /cka-training)
sudo htpasswd /etc/nginx/htpasswd-cka cka
sudo systemctl reload nginx
# System user 'cka' (used by ttyd and services)
sudo passwd cka
```

During install, you can optionally enter a domain to enable HTTPS via certbot. If provided, the installer prints final access URLs with https.

## Notes
- Use the printed context (`kubectl config current-context`) for each session.
- Each challenge prints its namespace and description. Work only in that namespace unless stated otherwise.
- Submissions after the time limit are marked but do not block grading.

## Access
- Desktop (docs-only): http(s)://<server-ip-or-domain>/cka-training/desktop
- Terminal (ttyd): http(s)://<server-ip-or-domain>/cka-training/terminal
- Live session page: http(s)://<server-ip-or-domain>/cka-training/session.html
- Scoreboard: http(s)://<server-ip-or-domain>/cka-training/scoreboard/
Auth: user `cka`, password `cka` (nginx basic auth; change after install).

## Web GUI
- Desktop environment with browser (via webtop) at `/cka-training/desktop`, locked to Kubernetes docs via local Squid proxy.
- Separate web terminal (ttyd) at `/cka-training/terminal`.
- Control API enables starting a session, grading (Done), moving to Next challenge, and reset actions via web.

Start a timed multi‑challenge session from the session page; progress and timers update live. Results sync to the scoreboard automatically.

## TLS and Domain
The installer prompts for an optional domain and, if provided, configures HTTPS via certbot automatically. Ensure your DNS A/AAAA record points to the server and port 80 is reachable.

You can also run manually:
```bash
bash scripts/webgui/setup-ssl.sh your.domain
```
