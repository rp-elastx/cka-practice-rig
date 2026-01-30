#!/usr/bin/env bash
set -euo pipefail

# Create three kind clusters and set up dynamic storage via local-path-provisioner
# Clusters: cka-a, cka-b, cka-c
# Kubeconfigs: kubeconfigs/cka-a.yaml, cka-b.yaml, cka-c.yaml, merged.yaml

REPO_DIR=$(cd "$(dirname "$0")/.." && pwd)
KUBECONFIG_DIR="$REPO_DIR/kubeconfigs"
CLUSTERS=("cka-a" "cka-b" "cka-c")
KIND_NODE_IMAGE_DEFAULT="kindest/node:v1.29.4"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Error: '$1' not found in PATH"; exit 1; }
}

need_cmd kind
need_cmd kubectl

mkdir -p "$KUBECONFIG_DIR"

create_cluster() {
  local name="$1"
  local image="${KIND_NODE_IMAGE:-$KIND_NODE_IMAGE_DEFAULT}"

  echo "[+] Creating kind cluster: $name (image=$image)"
  if kind get clusters | grep -qx "$name"; then
    echo "    Cluster '$name' already exists, skipping create"
  else
    kind create cluster --name "$name" --image "$image" --wait 120s
  fi

  echo "[+] Exporting kubeconfig for $name"
  kind get kubeconfig --name "$name" > "$KUBECONFIG_DIR/$name.yaml"

  # Install local-path-provisioner for dynamic storage
  echo "[+] Installing local-path-provisioner on $name"
  KUBECONFIG="$KUBECONFIG_DIR/$name.yaml" kubectl apply -f "$REPO_DIR/clusters/local-path-provisioner.yaml"

  # Wait for provisioner ready
  echo "[+] Waiting for local-path-provisioner ready on $name"
  KUBECONFIG="$KUBECONFIG_DIR/$name.yaml" kubectl -n local-path-storage rollout status deploy/local-path-provisioner --timeout=90s

  # Set default StorageClass
  echo "[+] Setting 'standard' as default StorageClass on $name"
  KUBECONFIG="$KUBECONFIG_DIR/$name.yaml" kubectl annotate sc standard storageclass.kubernetes.io/is-default-class="true" --overwrite || true
}

for c in "${CLUSTERS[@]}"; do
  create_cluster "$c"
done

# Merge kubeconfigs
"$REPO_DIR/scripts/merge-kubeconfigs.sh"

echo "[+] Done. Use: export KUBECONFIG=$KUBECONFIG_DIR/merged.yaml && kubectl config get-contexts"