#!/usr/bin/env bash
set -euo pipefail
REPO_DIR=$(cd "$(dirname "$0")/../.." && pwd)
KUBECONFIG_MERGED="$REPO_DIR/kubeconfigs/merged.yaml"
SCORE_DIR="$REPO_DIR/scoreboard"
SESSION_FILE="$SCORE_DIR/current-session.json"
RESULTS_FILE="$SCORE_DIR/results.json"

if [ ! -f "$SESSION_FILE" ]; then
  echo "Error: no current session found at $SESSION_FILE"
  exit 1
fi

python3 - "$SESSION_FILE" <<'PY'
import sys,json,datetime
with open(sys.argv[1]) as f:
    s=json.load(f)
start=datetime.datetime.fromisoformat(s['start'])
limit=s['timeLimitSeconds']
now=datetime.datetime.now(datetime.timezone.utc).astimezone()
elapsed=(now-start).total_seconds()
print(int(elapsed))
print(s['context'])
print(s['gradeScript'])
print(s['challengeId'])
PY

read -r elapsed ctx grader chal_id < <(python3 - "$SESSION_FILE" <<'PY'
import sys,json,datetime
with open(sys.argv[1]) as f:
    s=json.load(f)
start=datetime.datetime.fromisoformat(s['start'])
limit=s['timeLimitSeconds']
now=datetime.datetime.now(datetime.timezone.utc).astimezone()
elapsed=(now-start).total_seconds()
print(int(elapsed))
print(s['context'])
print(s['gradeScript'])
print(s['challengeId'])
PY
)

export KUBECONFIG="$KUBECONFIG_MERGED"
kubectl config use-context "$ctx" >/dev/null

user="${USER:-unknown}"
status="FAIL"

if "$grader"; then
  status="PASS"
fi

on_time="true"
limit=$(python3 -c "import json;print(json.load(open('$SESSION_FILE'))['timeLimitSeconds'])")
if [ "$elapsed" -gt "$limit" ]; then
  on_time="false"
fi

mkdir -p "$SCORE_DIR"
[ -f "$RESULTS_FILE" ] || echo "[]" > "$RESULTS_FILE"

python3 - "$RESULTS_FILE" "$SESSION_FILE" "$status" "$elapsed" "$on_time" "$user" <<'PY'
import sys,json
resf, sessf, status, elapsed, on_time, user = sys.argv[1:]
with open(resf) as f:
    arr=json.load(f)
with open(sessf) as f:
    s=json.load(f)
arr.append({
  "challengeId": s['challengeId'],
  "title": s['title'],
  "context": s['context'],
  "user": user,
  "status": status,
  "elapsedSeconds": int(elapsed),
  "onTime": on_time == 'true'
})
with open(resf,'w') as f:
    json.dump(arr,f,indent=2)
print('OK')
PY

echo "[submit] $status for $chal_id by $user in ${elapsed}s (onTime=$on_time). See scoreboard/results.json."