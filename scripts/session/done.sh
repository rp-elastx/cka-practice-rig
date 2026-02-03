#!/usr/bin/env bash
set -euo pipefail
REPO_DIR=$(cd "$(dirname "$0")/../.." && pwd)
KUBECONFIG_MERGED="$REPO_DIR/kubeconfigs/merged.yaml"
SCORE_DIR="$REPO_DIR/scoreboard"
SESSION_FILE="$SCORE_DIR/current-session.json"
RESULTS_FILE="$SCORE_DIR/results.json"
SESSION_META="$SCORE_DIR/session.json"

[ -f "$SESSION_FILE" ] || { echo "Error: no current session" >&2; exit 1; }
[ -f "$SESSION_META" ] || { echo "Error: no session meta" >&2; exit 1; }

export KUBECONFIG="$KUBECONFIG_MERGED"

ctx=$(python3 -c "import json;print(json.load(open('$SESSION_FILE'))['context'])")
grader=$(python3 -c "import json;print(json.load(open('$SESSION_FILE'))['gradeScript'])")
chal_id=$(python3 -c "import json;print(json.load(open('$SESSION_FILE'))['challengeId'])")
start=$(python3 -c "import json;print(json.load(open('$SESSION_FILE'))['start'])")
limit=$(python3 -c "import json;print(json.load(open('$SESSION_FILE'))['timeLimitSeconds'])")

kubectl config use-context "$ctx" >/dev/null

# Compute elapsed
elapsed=$(python3 - "$start" <<'PY'
import sys,datetime
start=datetime.datetime.fromisoformat(sys.argv[1])
now=datetime.datetime.now(datetime.timezone.utc).astimezone()
print(int((now-start).total_seconds()))
PY
)

# Grade
user="${USER:-unknown}"
status="FAIL"
if "$grader"; then status="PASS"; fi
on_time="true"
[ "$elapsed" -gt "$limit" ] && on_time="false"

# Append to results
mkdir -p "$SCORE_DIR"
[ -f "$RESULTS_FILE" ] || echo "[]" > "$RESULTS_FILE"
python3 - "$RESULTS_FILE" "$SESSION_FILE" "$status" "$elapsed" "$on_time" "$user" <<'PY'
import sys,json
resf, sessf, status, elapsed, on_time, user = sys.argv[1:]
arr=json.load(open(resf))
s=json.load(open(sessf))
arr.append({
  "sessionId": s.get('sessionId'),
  "index": s.get('index'),
  "challengeId": s['challengeId'],
  "title": s['title'],
  "context": s['context'],
  "user": user,
  "status": status,
  "elapsedSeconds": int(elapsed),
  "onTime": on_time == 'true'
})
json.dump(arr,open(resf,'w'),indent=2)
print('OK')
PY

echo "[session] Graded $chal_id: $status (${elapsed}s, onTime=$on_time)."