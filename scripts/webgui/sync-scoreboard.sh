#!/usr/bin/env bash
set -euo pipefail
REPO_DIR=$(cd "$(dirname "$0")/../.." && pwd)
SCORE_DIR="$REPO_DIR/scoreboard"
WWW_DIR="/var/www/cka-practice"

sudo rsync -a "$SCORE_DIR/" "$WWW_DIR/scoreboard/"
echo "[sync] Copied scoreboard to $WWW_DIR/scoreboard"