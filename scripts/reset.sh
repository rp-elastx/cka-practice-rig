#!/usr/bin/env bash
set -euo pipefail
REPO_DIR=$(cd "$(dirname "$0")/.." && pwd)
CLUSTERS=("cka-a" "cka-b" "cka-c")

for c in "${CLUSTERS[@]}"; do
  echo "[reset] Deleting cluster $c"
  kind delete cluster --name "$c" || true
done

echo "[reset] Cleaning kubeconfigs and session/scoreboard"
rm -f "$REPO_DIR"/kubeconfigs/*.yaml || true
rm -f "$REPO_DIR"/scoreboard/current-session.json || true
rm -f "$REPO_DIR"/scoreboard/results.json || true

echo "[reset] Done. Run scripts/setup.sh to start fresh."