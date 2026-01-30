# CKA Practice Rig

Self-hosted CKA practice platform with kind-based multi-cluster, randomized challenges, automated grading, time limits, and a scoreboard.

## Features
- Multiple kind clusters and merged kubeconfig with distinct contexts
- 6 ready-made challenges: storage, deployment, service, network policy, RBAC, troubleshooting
- Randomized target context per challenge
- Time limit tracking and pass/fail grading
- Resettable environment and simple scoreboard (JSON + HTML)

## Prerequisites
- Linux/macOS, Bash
- kind, kubectl, Python 3

## Quickstart
```bash
# Install dependencies, web GUI, and clusters
bash scripts/install.sh

# Optional: set up docs-only desktop
bash scripts/webgui/setup-docs-proxy.sh
bash scripts/webgui/setup-desktop.sh

# Set cka password (change from default)
sudo passwd cka
```

## Notes
- Use the printed context (`kubectl config current-context`) for each session.
- Each challenge prints its namespace and description. Work only in that namespace unless stated otherwise.
- Submissions after the time limit are marked but do not block grading.

## Access
- Desktop + terminal + docs: http(s)://<server-ip-or-domain>/cka-training/desktop
- Live session page: http(s)://<server-ip-or-domain>/cka-training/session.html
- Scoreboard: http(s)://<server-ip-or-domain>/cka-training/scoreboard/
Auth: user `cka`, password `cka` (change after install).

## Web GUI
- Single desktop environment with terminal and browser (via webtop) under `/cka-training/desktop`.
- Squid proxy optionally restricts browsing to Kubernetes docs domains.
- Control API enables starting a session and reset actions via web.

## TLS and Domain
To serve on your domain (e.g., vanskapt.se) with HTTPS:
```bash
# Set server_name and obtain certificates
bash scripts/webgui/setup-ssl.sh vanskapt.se
```
Ensure DNS A/AAAA record points to the server and port 80 is reachable before running the script.
