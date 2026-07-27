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

HUB_URL="${MXCLI_HUB_URL:-https://hub.mxcli.org}"
HUB_SECRET="${MXCLI_HUB_SECRET:-}"

log() { printf '[run-app] %s\n' "$*"; }

command -v mxcli >/dev/null 2>&1 || { log "mxcli not on PATH yet — skipping app launch"; exit 0; }
[ -f "$MPR" ] || { log "no project at $MPR — nothing to run"; exit 0; }

# Idempotent: never start a second instance.
if pgrep -f "mxcli run .*Sudoku\.mpr" >/dev/null 2>&1; then
  log "app already running — leaving it as-is"
  exit 0
fi

mkdir -p "$LOG_DIR"

if [ -n "$HUB_SECRET" ]; then
  # --hub implies --local; the app stays local and is reverse-tunnelled out.
  set -- run --hub "$HUB_URL" --hub-secret "$HUB_SECRET" --ensure-db --watch -p "$MPR"
  log "launching with hub registration ($HUB_URL)"
else
  set -- run --local --ensure-db --watch -p "$MPR"
  log "MXCLI_HUB_SECRET not set — launching locally on 127.0.0.1:8080 (no public preview)."
  log "Set MXCLI_HUB_SECRET (and optionally MXCLI_HUB_URL) in the environment for auto hub registration."
fi

nohup mxcli "$@" >"$LOG" 2>&1 &
disown 2>/dev/null || true
log "app launching in background (PID $!) — boot progress in $LOG"
log "once booted, the preview URL is printed in that log (grep 'Preview available')."
exit 0
