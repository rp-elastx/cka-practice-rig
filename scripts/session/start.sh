#!/usr/bin/env bash
set -euo pipefail
REPO_DIR=$(cd "$(dirname "$0")/../.." && pwd)
KUBECONFIG_MERGED="$REPO_DIR/kubeconfigs/merged.yaml"
CHAL_DIR="$REPO_DIR/challenges"
SCORE_DIR="$REPO_DIR/scoreboard"
SESSION_FILE="$SCORE_DIR/current-session.json"
SESSION_META="$SCORE_DIR/session.json"
TOTAL_LIMIT="${SESSION_TIME_LIMIT:-7200}"

if [ ! -f "$KUBECONFIG_MERGED" ]; then
  echo "Error: merged kubeconfig not found at $KUBECONFIG_MERGED. Run scripts/setup.sh first." >&2
  exit 1
fi

# Collect challenges and pick 10 unique random
mapfile -t challenges < <(ls "$CHAL_DIR"/*.yaml)
count=${#challenges[@]}
if [ "$count" -eq 0 ]; then
  echo "Error: no challenges found in $CHAL_DIR" >&2
  exit 1
fi

# Shuffle and take up to 10
shuf_list=($(printf '%s\n' "${challenges[@]}" | shuf))
sel_list=(${shuf_list[@]:0:10})

# Pick random context
mapfile -t contexts < <(KUBECONFIG="$KUBECONFIG_MERGED" kubectl config get-contexts -o name)
if [ ${#contexts[@]} -eq 0 ]; then
  echo "Error: no contexts in merged kubeconfig" >&2
  exit 1
fi

# Build session metadata
session_id=$(date +%Y%m%d-%H%M%S)-$RANDOM
session_start=$(date -Iseconds)
cat > "$SESSION_META" <<EOF
{
  "sessionId": "$session_id",
  "total": ${#sel_list[@]},
  "currentIndex": 0,
  "sessionStart": "$session_start",
  "totalTimeLimitSeconds": $TOTAL_LIMIT,
  "challenges": [
$(for i in "${!sel_list[@]}"; do
  f="${sel_list[$i]}";
  id=$(python3 -c "import yaml,sys;print(yaml.safe_load(open(sys.argv[1]))['id'])" "$f");
  printf '    {"file":"%s","id":"%s"}%s\n' "$f" "$id" $([ "$i" -lt $((${#sel_list[@]}-1)) ] && echo ,);
 done)
  ]
}
EOF

# Function to parse YAML
get_yaml() { python3 -c "import sys,yaml;print(yaml.safe_load(open(sys.argv[1]))[sys.argv[2]])" "$1" "$2"; }

# Setup first challenge
idx=0
chal_file=${sel_list[$idx]}
chal_id=$(get_yaml "$chal_file" id)
chal_title=$(get_yaml "$chal_file" title)
chal_ns=$(get_yaml "$chal_file" namespace)
chal_setup_rel=$(get_yaml "$chal_file" setup)
chal_grade_rel=$(get_yaml "$chal_file" grade)
chal_limit=$(get_yaml "$chal_file" timeLimitSeconds)
chal_desc=$(get_yaml "$chal_file" description)
chal_setup=$(realpath -m "$CHAL_DIR/$(basename "$chal_setup_rel")" 2>/dev/null || realpath -m "$REPO_DIR/scripts/challenges/$(basename "$chal_setup_rel")")
chal_grade=$(realpath -m "$REPO_DIR/grading/$(basename "$chal_grade_rel")")

# Random context
ctx=${contexts[$((RANDOM % ${#contexts[@]}))]}

# Persist session state for current challenge
start_ts=$(date -Iseconds)
cat > "$SESSION_FILE" <<EOF
{
  "sessionId": "$session_id",
  "index": $idx,
  "total": ${#sel_list[@]},
  "challengeId": "$chal_id",
  "title": "$chal_title",
  "namespace": "$chal_ns",
  "challengeFile": "$(basename "$chal_file")",
  "setupScript": "$chal_setup",
  "gradeScript": "$chal_grade",
  "timeLimitSeconds": $chal_limit,
  "context": "$ctx",
  "start": "$start_ts",
  "description": $(python3 -c "import yaml,sys,json;print(json.dumps(yaml.safe_load(open(sys.argv[1]))['description']))" "$chal_file")
}
EOF

# Run setup against selected context
export KUBECONFIG="$KUBECONFIG_MERGED"
kubectl config use-context "$ctx" >/dev/null
"$chal_setup"

echo "[session] Started session $session_id with ${#sel_list[@]} challenges. Current: $chal_id (index $idx)."