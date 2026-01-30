#!/usr/bin/env bash
set -euo pipefail
REPO_DIR=$(cd "$(dirname "$0")/.." && pwd)
RESULTS="$REPO_DIR/scoreboard/results.json"
if [ ! -f "$RESULTS" ]; then
  echo "No results yet."
  exit 0
fi
python3 - "$RESULTS" <<'PY'
import sys,json
arr=json.load(open(sys.argv[1]))
print(f"Total results: {len(arr)}")
for i, r in enumerate(arr, 1):
    print(f"{i}. {r['user']} | {r['challengeId']} | {r['context']} | {r['status']} | {r['elapsedSeconds']}s | onTime={r['onTime']}")
PY