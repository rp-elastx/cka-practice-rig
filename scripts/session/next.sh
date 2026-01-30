#!/usr/bin/env bash
set -euo pipefail
REPO_DIR=$(cd "$(dirname "$0")/../.." && pwd)
KUBECONFIG_MERGED="$REPO_DIR/kubeconfigs/merged.yaml"
CHAL_DIR="$REPO_DIR/challenges"
SCORE_DIR="$REPO_DIR/scoreboard"
SESSION_FILE="$SCORE_DIR/current-session.json"
SESSION_META="$SCORE_DIR/session.json"

[ -f "$SESSION_META" ] || { echo "Error: no session meta" >&2; exit 1; }

current=$(python3 -c "import json;print(json.load(open('$SESSION_META'))['currentIndex'])")
total=$(python3 -c "import json;print(json.load(open('$SESSION_META'))['total'])")
if [ "$current" -ge "$total" ]; then
  echo "[session] All challenges completed." >&2
  exit 0
fi

# Increment index
python3 - "$SESSION_META" <<'PY'
import sys,json
p=sys.argv[1]
s=json.load(open(p))
s['currentIndex'] = s['currentIndex'] + 1
json.dump(s,open(p,'w'),indent=2)
print(s['currentIndex'])
PY

new_idx=$(python3 -c "import json;print(json.load(open('$SESSION_META'))['currentIndex'])")
if [ "$new_idx" -ge "$total" ]; then
  echo "[session] Completed all challenges." >&2
  exit 0
fi

# Get challenge file for new_idx
chal_file=$(python3 -c "import json;print(json.load(open('$SESSION_META'))['challenges'][$new_idx]['file'])")

# Parse challenge metadata
get_yaml() { python3 -c "import sys,yaml;print(yaml.safe_load(open(sys.argv[1]))[sys.argv[2]])" "$1" "$2"; }
chal_id=$(get_yaml "$chal_file" id)
chal_title=$(get_yaml "$chal_file" title)
chal_ns=$(get_yaml "$chal_file" namespace)
chal_setup_rel=$(get_yaml "$chal_file" setup)
chal_grade_rel=$(get_yaml "$chal_file" grade)
chal_limit=$(get_yaml "$chal_file" timeLimitSeconds)
chal_desc=$(get_yaml "$chal_file" description)
chal_setup=$(realpath -m "$CHAL_DIR/$(basename "$chal_setup_rel")" 2>/dev/null || realpath -m "$REPO_DIR/scripts/challenges/$(basename "$chal_setup_rel")")
chal_grade=$(realpath -m "$REPO_DIR/grading/$(basename "$chal_grade_rel")")

# Pick random context
mapfile -t contexts < <(KUBECONFIG="$KUBECONFIG_MERGED" kubectl config get-contexts -o name)
ctx=${contexts[$((RANDOM % ${#contexts[@]}))]}

# Persist current challenge state
start_ts=$(date -Iseconds)
cat > "$SESSION_FILE" <<EOF
{
  "sessionId": $(python3 -c "import json;print(json.load(open('$SESSION_META'))['sessionId'])" | sed 's/^/"/;s/$/"/'),
  "index": $new_idx,
  "total": $total,
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

echo "[session] Next challenge: $chal_id (index $new_idx/$total)."