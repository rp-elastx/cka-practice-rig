#!/usr/bin/env bash
set -euo pipefail
REPO_DIR=$(cd "$(dirname "$0")/.." && pwd)
CLUSTERS=("cka-a" "cka-b" "cka-c")

for c in "${CLUSTERS[@]}"; do
  echo "[reset] Deleting cluster $c"
  kind delete cluster --name "$c" || true
done

echo "[reset] Cleaning kubeconfigs and current session (preserving scoreboard history)"
rm -f "$REPO_DIR"/kubeconfigs/*.yaml || true
rm -f "$REPO_DIR"/scoreboard/current-session.json || true
# Note: results.json is preserved to keep scoreboard history

echo "[reset] Done. Run scripts/setup.sh to start fresh."