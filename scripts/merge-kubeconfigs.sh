#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=$(cd "$(dirname "$0")/.." && pwd)
KUBECONFIG_DIR="$REPO_DIR/kubeconfigs"
CLUSTERS=("cka-a" "cka-b" "cka-c")
MERGED="$KUBECONFIG_DIR/merged.yaml"

# Merge kubeconfigs for all clusters
export KUBECONFIG=$(printf "%s:" "$KUBECONFIG_DIR"/*.yaml)
export KUBECONFIG=${KUBECONFIG%:}

if [ -z "${KUBECONFIG}" ]; then
  echo "Error: no kubeconfig files found in $KUBECONFIG_DIR"
  exit 1
fi

kubectl config view --merge --flatten > "$MERGED"

# Normalize context names to cluster names
for c in "${CLUSTERS[@]}"; do
  ctx=$(KUBECONFIG="$MERGED" kubectl config get-contexts -o name | grep "$c" || true)
  if [ -n "$ctx" ] && [ "$ctx" != "$c" ]; then
    KUBECONFIG="$MERGED" kubectl config rename-context "$ctx" "$c"
  fi
  # Also set a convenient user and cluster naming if needed
done

# Set current context to first cluster
KUBECONFIG="$MERGED" kubectl config use-context "${CLUSTERS[0]}"

echo "[+] Merged kubeconfig written to $MERGED"
echo "[+] Contexts:"; KUBECONFIG="$MERGED" kubectl config get-contexts