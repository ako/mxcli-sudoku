#!/usr/bin/env bash
#
# run-app.sh — idempotently launch the scaffolded Mendix app via mxcli in the
# background, registering it with the tunnel-hub when a secret is available.
#
# Invoked by the SessionStart hook (after setup-tools.sh) so a new, ephemeral
# session comes up with the app already running — and, when the hub secret is
# present, a public browser-preview URL.
#
# Hub credentials are read from the ENVIRONMENT, never committed:
#   MXCLI_HUB_URL     hub control URL (default https://hub.mxcli.org)
#   MXCLI_HUB_SECRET  shared "user:pass" secret; when unset, the app runs
#                     locally only (127.0.0.1:8080, no public preview).
# Set these in the Claude Code environment configuration for auto hub
# registration that survives container recycling.
#
# This script always exits 0 so it can never block or fail a session start.
set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MPR="${PROJECT_DIR}/Sudoku/Sudoku.mpr"
LOG_DIR="${PROJECT_DIR}/Sudoku/.mxcli"
LOG="${LOG_DIR}/run-app.log"
SPANS="${LOG_DIR}/spans.jsonl"
OTLP="http://127.0.0.1:4318"

HUB_URL="${MXCLI_HUB_URL:-https://hub.mxcli.org}"
HUB_SECRET="${MXCLI_HUB_SECRET:-}"

log() { printf '[run-app] %s\n' "$*"; }

command -v mxcli >/dev/null 2>&1 || { log "mxcli not on PATH yet — skipping app launch"; exit 0; }
[ -f "$MPR" ] || { log "no project at $MPR — nothing to run"; exit 0; }

# Idempotent: never start a second instance. One exception — setup-tools.sh may
# have just replaced /usr/local/bin/mxcli underneath a running app, which leaves
# it holding a deleted inode and silently serving the OLD build. Restart those.
RUNNING="$(pgrep -f "mxcli run .*Sudoku\.mpr" | head -1)"
if [ -n "$RUNNING" ]; then
  if readlink "/proc/$RUNNING/exe" 2>/dev/null | grep -q '(deleted)'; then
    log "running app is on a replaced mxcli binary — restarting it"
    kill -TERM "$RUNNING" 2>/dev/null
    sleep 5
    for p in $(ps -eo pid,args --no-headers |
               grep -E 'mxbuild|runtimelauncher|rollup-runner|esbuild' |
               grep -v grep | awk '{print $1}'); do kill -KILL "$p" 2>/dev/null; done
    sleep 2
  else
    log "app already running — leaving it as-is"
    exit 0
  fi
fi

mkdir -p "$LOG_DIR"

# Span sink for --trace-otlp. Without a listener the runtime just drops spans,
# so the collector has to be up before the app boots.
# curl exits 7 on "connection refused"; a live collector answers the GET (501,
# it only accepts POST) and exits 0.
curl -s -m 3 -o /dev/null "$OTLP/v1/traces"
if [ $? -ne 7 ]; then
  log "OTLP collector already listening on :4318"
else
  nohup python3 "${PROJECT_DIR}/scripts/otlp-collect.py" --out "$SPANS" \
    >"${LOG_DIR}/otlp-collect.log" 2>&1 &
  disown 2>/dev/null || true
  log "OTLP collector started -> $SPANS"
fi

# Observability is on by default: a relaunch after a container suspend has to
# come back with the same instrumentation, or the app silently loses its traces
# and metrics for the rest of the session.
OBS=(--metrics --trace-otlp "$OTLP")

if [ -n "$HUB_SECRET" ]; then
  # --hub implies --local; the app stays local and is reverse-tunnelled out.
  # MXCLI_HUB_KEY in the environment authenticates on its own; the shared secret
  # is passed only as a fallback for a hub that still accepts one.
  set -- run --hub "$HUB_URL" --hub-secret "$HUB_SECRET" --ensure-db --watch "${OBS[@]}" -p "$MPR"
  log "launching with hub registration ($HUB_URL)"
else
  set -- run --local --ensure-db --watch "${OBS[@]}" -p "$MPR"
  log "MXCLI_HUB_SECRET not set — launching locally on 127.0.0.1:8080 (no public preview)."
  log "Set MXCLI_HUB_SECRET (and optionally MXCLI_HUB_URL) in the environment for auto hub registration."
fi

nohup mxcli "$@" >"$LOG" 2>&1 &
disown 2>/dev/null || true
log "app launching in background (PID $!) — boot progress in $LOG"
log "once booted, the preview URL is printed in that log (grep 'Preview available')."
exit 0
