#!/usr/bin/env bash
# Verify the app + hub tunnel + OTLP collector are up; relaunch whatever is not.
#
# The container is suspended whenever the agent session goes idle, which kills
# every process in it. This is the recovery step run on each wake-up: it is
# cheap when everything is healthy, and rebuilds the whole stack when it is not.
set -uo pipefail

ROOT=/home/user/mxcli-sudoku
OBS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREVIEW=https://sudoku-claude-mendix-mxcli-workspace-setup-020uo3.mxcli.org/
cd "$ROOT" || exit 1

up() { [ "$(curl -s -m 5 -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/)" = "200" ]; }
collector_up() { curl -s -m 3 -o /dev/null http://127.0.0.1:4318/v1/traces; [ $? -ne 7 ]; }

if ! collector_up; then
  nohup python3 scripts/otlp-collect.py --out "$OBS/spans.jsonl" >"$OBS/collector.log" 2>&1 &
  disown 2>/dev/null || true
  echo "collector: restarted"
else
  echo "collector: ok"
fi

PID="$(pgrep -f '^mxcli run' | head -1)"

# A boot takes ~90s. Killing an app that is merely still starting restarts the
# clock forever, so wait it out before concluding anything is wrong.
if [ -n "$PID" ] && ! up; then
  echo "app: booting (pid $PID, $(ps -o etime= -p "$PID" | tr -d ' ')) — waiting"
  for i in $(seq 1 18); do sleep 10; up && break; done
fi

if up; then
  echo "app: ok (uptime $(ps -o etime= -p "$(pgrep -f '^mxcli run' | head -1)" 2>/dev/null | tr -d ' '))"
else
  echo "app: DOWN — relaunching"
  kill -TERM $(pgrep -f '^mxcli run') 2>/dev/null
  sleep 5
  for p in $(ps -eo pid,args --no-headers |
             grep -E 'mxbuild|runtimelauncher|rollup-runner|esbuild' |
             grep -v grep | awk '{print $1}'); do kill -KILL "$p" 2>/dev/null; done
  nohup mxcli run --hub "${MXCLI_HUB_URL:-https://hub.mxcli.org}" --ensure-db --watch \
    --metrics --trace-otlp http://127.0.0.1:4318 \
    -p Sudoku/Sudoku.mpr >Sudoku/.mxcli/run-app.log 2>&1 &
  disown 2>/dev/null || true
  for i in $(seq 1 18); do sleep 10; up && break; done
  up && echo "app: back up" || { echo "app: STILL DOWN"; tail -5 Sudoku/.mxcli/run-app.log; }
fi

echo "hub tunnel: HTTP $(curl -s -m 15 -o /dev/null -w '%{http_code}' "$PREVIEW") (302 = OAuth gate, healthy)"
