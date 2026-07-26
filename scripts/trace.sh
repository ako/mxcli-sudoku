#!/usr/bin/env bash
# Follow the app's microflow trace.
#
# Every action microflow logs its own name (and the digit / square where that
# is the interesting part) to the log node 'Sudoku'. mxcli's warm loop wires
# the Mendix application log into Sudoku/.mxcli/runtime.log, so using the UI
# prints the call chain here in real time.
#
#   scripts/trace.sh            # follow live
#   scripts/trace.sh -n 40      # last 40 trace lines, then follow
#   scripts/trace.sh --all      # everything so far, no follow
set -uo pipefail

LOG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/Sudoku/.mxcli/runtime.log"

if [ ! -f "$LOG" ]; then
  echo "no runtime log at $LOG — is the app running? (scripts/run-app.sh)" >&2
  exit 1
fi

# 'HH:MM:SS  ACT_Name detail' — drop the date and the log-node prefix.
tidy() { sed -n 's/^[0-9-]* \([0-9:]*\)\.[0-9]* INFO - Sudoku: /\1  /p'; }

case "${1:-}" in
  --all) tidy < "$LOG" ;;
  -n)    { tail -n "${2:-20}" "$LOG" | tidy; tail -f -n 0 "$LOG" | tidy; } ;;
  *)     tail -f -n 0 "$LOG" | tidy ;;
esac
