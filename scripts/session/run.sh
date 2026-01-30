#!/usr/bin/env bash
set -euo pipefail
REPO_DIR=$(cd "$(dirname "$0")/../.." && pwd)
KUBECONFIG_MERGED="$REPO_DIR/kubeconfigs/merged.yaml"
CHAL_DIR="$REPO_DIR/challenges"
SCORE_DIR="$REPO_DIR/scoreboard"
SESSION_FILE="$SCORE_DIR/current-session.json"

if [ ! -f "$KUBECONFIG_MERGED" ]; then
  echo "Error: merged kubeconfig not found at $KUBECONFIG_MERGED. Run scripts/setup.sh first."
  exit 1
fi

# Pick random challenge
mapfile -t challenges < <(ls "$CHAL_DIR"/*.yaml)
count=${#challenges[@]}
if [ "$count" -eq 0 ]; then
  echo "Error: no challenges found in $CHAL_DIR"
  exit 1
fi
chal_file=${challenges[$((RANDOM % count))]}

# Parse challenge metadata
get_yaml() { python3 -c "import sys,yaml;print(yaml.safe_load(open(sys.argv[1]))[sys.argv[2]])" "$1" "$2"; }
chal_id=$(get_yaml "$chal_file" id)
chal_title=$(get_yaml "$chal_file" title)
chal_ns=$(get_yaml "$chal_file" namespace)
chal_setup_rel=$(get_yaml "$chal_file" setup)
chal_grade_rel=$(get_yaml "$chal_file" grade)
chal_limit=$(get_yaml "$chal_file" timeLimitSeconds)
chal_desc=$(get_yaml "$chal_file" description)
chal_setup=$(realpath -m "$CHAL_DIR/$chal_setup_rel" 2>/dev/null || realpath -m "$REPO_DIR/scripts/challenges/$(basename "$chal_setup_rel")")
chal_grade=$(realpath -m "$REPO_DIR/grading/$(basename "$chal_grade_rel")")

# Pick random context
mapfile -t contexts < <(KUBECONFIG="$KUBECONFIG_MERGED" kubectl config get-contexts -o name)
ctx=${contexts[$((RANDOM % ${#contexts[@]}))]}

# Persist session metadata
start_ts=$(date -Iseconds)
cat > "$SESSION_FILE" <<EOF
{
  "challengeId": "$chal_id",
  "title": "$chal_title",
  "namespace": "$chal_ns",
  "challengeFile": "$(basename "$chal_file")",
  "setupScript": "$chal_setup",
  "gradeScript": "$chal_grade",
  "timeLimitSeconds": $chal_limit,
  "context": "$ctx",
  "start": "$start_ts"
}
EOF

# Run setup against selected context
export KUBECONFIG="$KUBECONFIG_MERGED"
kubectl config use-context "$ctx" >/dev/null
echo "[session] Context: $ctx"
"$chal_setup"

echo "\n=== Challenge ==="
echo "ID: $chal_id"
echo "Title: $chal_title"
echo "Namespace: $chal_ns"
echo "Time limit: $chal_limit seconds"
echo "Context: $ctx"
echo "\nDescription:\n$chal_desc"
echo "\nWork in this context. When ready, run scripts/session/submit.sh."