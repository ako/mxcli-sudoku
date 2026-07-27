#!/usr/bin/env bash
# Drive the Mendix microflow debugger from the shell.
#
# Two APIs are involved. The M2EE admin API on :8090 only switches the debugger
# on and off; breakpoints, paused flows and variables live on a second endpoint
# the runtime serves at <app>/debugger/, which is what Studio Pro talks to.
#
#   scripts/mfdebug.sh enable                      # turn the debugger on
#   scripts/mfdebug.sh session                     # open a debug session (caches the token)
#   scripts/mfdebug.sh activities Sudoku.ACT_SelectCell
#   scripts/mfdebug.sh break Sudoku.ACT_SelectCell <object-id>
#   scripts/mfdebug.sh paused                      # what is stopped, with variables
#   scripts/mfdebug.sh object <debug-id> Cell      # expand one object variable
#   scripts/mfdebug.sh step over|into|out <debug-id>
#   scripts/mfdebug.sh continue                    # resume everything
#   scripts/mfdebug.sh unbreak <object-id>
#   scripts/mfdebug.sh disable                     # always finish with this
#
# Nanoflows run in the browser but break through the same endpoint:
#
#   scripts/mfdebug.sh nactivities Sudoku.NF_ToggleNotes
#   scripts/mfdebug.sh nbreak Sudoku.NF_ToggleNotes <object-id>
#   scripts/mfdebug.sh events                      # paused NANOflows show up here,
#                                                  # never in 'paused'
#
# A breakpoint pauses whoever hits it, including a real user in a browser —
# 'continue' and 'disable' are how you give the app back.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="${MXCLI_PROJECT:-$ROOT/Sudoku/Sudoku.mpr}"
APP="${MXCLI_APP_URL:-http://127.0.0.1:8080}"
ADMIN="${MXCLI_ADMIN_URL:-http://127.0.0.1:8090}"
ADMIN_PASS="${MXCLI_ADMIN_PASS:-mxcli-local-dev}"
DEBUG_PASS="${MXCLI_DEBUG_PASS:-mxdebug}"
TOKEN_FILE="${TMPDIR:-/tmp}/mxcli-debug-session.token"

b64() { printf '%s' "$1" | base64 | tr -d '\n'; }
pretty() { python3 -m json.tool 2>/dev/null || cat; }

admin() { # admin <action> [params-json]
  curl -s -m 15 -H "X-M2EE-Authentication: $(b64 "$ADMIN_PASS")" \
    -H 'Content-Type: application/json' \
    -d "{\"action\":\"$1\"${2:+,\"params\":$2}}" "$ADMIN/"
}

dbg() { # dbg <action> <params-json> [--no-token]
  local body
  if [ "${3:-}" = "--no-token" ]; then
    body="{\"action\":\"$1\",\"params\":$2}"
  else
    [ -s "$TOKEN_FILE" ] || { echo "no debug session — run: $0 session" >&2; exit 1; }
    body="{\"action\":\"$1\",\"session_token\":\"$(cat "$TOKEN_FILE")\",\"params\":$2}"
  fi
  curl -s -m 60 -H "X-Debugger-Authentication: $(b64 "$DEBUG_PASS")" \
    -H 'Content-Type: application/json' -d "$body" "$APP/debugger/"
}

# List every breakpointable object in a flow: id, position, action, kind.
#
# These are the model's own object GUIDs. mxcli's catalog already holds them —
# activities_data.Id is the same GUID the debugger takes, alongside the action
# name and its position in the flow, which the raw model does not hand you as
# readably. Needs `mxcli -c "REFRESH CATALOG FULL"`; plain REFRESH leaves
# activities_data empty, so the BSON walk stays as a fallback.
activities() {
  local flow="$1" kind="${2:-microflow}" mx="$ROOT/Sudoku/mxcli"
  local cat="$ROOT/Sudoku/.mxcli/catalog.db"
  [ -x "$mx" ] || mx=mxcli

  if [ -f "$cat" ]; then
    local rows
    rows=$(python3 -c '
import sqlite3, sys
db, flow = sys.argv[1], sys.argv[2]
try:
    con = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
    rows = con.execute(
        "SELECT Id, Name, ActivityType, Sequence FROM activities_data "
        "WHERE MicroflowQualifiedName = ? ORDER BY Sequence", (flow,)).fetchall()
except sqlite3.Error:
    rows = []
for gid, name, typ, seq in rows:
    print(f"{gid}  {seq:>3}  {name:<24} {typ}")
' "$cat" "$flow")
    if [ -n "$rows" ]; then printf '%s\n' "$rows"; return; fi
    echo "  (catalog has no activities for $flow — run: mxcli -c 'REFRESH CATALOG FULL')" >&2
  fi

  # Fallback: read the GUIDs out of the .mpr itself (BSON stores them as
  # little-endian .NET GUIDs, hence bytes_le).
  "$mx" bson dump -p "$PROJECT" -t "$kind" -o "$flow" 2>/dev/null |
  python3 -c '
import json, base64, uuid, sys
def walk(n, out):
    if isinstance(n, list):
        p = {x["Key"]: x["Value"] for x in n if isinstance(x, dict) and "Key" in x}
        i = p.get("$ID")
        if isinstance(i, dict) and "Data" in i and "$Type" in p:
            out.append((str(uuid.UUID(bytes_le=base64.b64decode(i["Data"]))),
                        p["$Type"], p.get("Caption") or p.get("Name") or ""))
        for x in n: walk(x, out)
    elif isinstance(n, dict):
        for v in n.values(): walk(v, out)
out, seen = [], set()
walk(json.load(sys.stdin), out)
for g, t, c in out:
    if g in seen or not t.startswith("Microflows$"): continue
    seen.add(g)
    kind = t.split("$", 1)[1]
    if kind in ("ActionActivity", "ExclusiveSplit", "LoopedActivity", "EndEvent", "StartEvent"):
        print(f"{g}  {kind:<16} {str(c)[:48]}")
'
}

case "${1:-}" in
  enable)   admin enable_debugger "{\"password\":\"$DEBUG_PASS\"}" | pretty ;;
  disable)  rm -f "$TOKEN_FILE"; admin disable_debugger | pretty ;;
  status)   admin get_debugger_status | pretty ;;

  session)
    out=$(dbg start_session '{"breakpoints":[]}' --no-token)
    tok=$(printf '%s' "$out" | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"].get("session_token",""))' 2>/dev/null)
    [ -n "$tok" ] || { echo "could not start a session (is the debugger enabled?):" >&2; printf '%s\n' "$out" >&2; exit 1; }
    printf '%s' "$tok" > "$TOKEN_FILE"
    printf '%s\n' "$out" | pretty ;;

  activities)  activities "${2:?usage: $0 activities Module.Microflow}" microflow ;;
  nactivities) activities "${2:?usage: $0 nactivities Module.Nanoflow}" nanoflow ;;

  break)
    dbg add_breakpoint "{\"microflow_name\":\"${2:?need a microflow}\",\"object_id\":\"${3:?need an object id}\",\"condition\":\"${4:-}\"}" | pretty ;;
  nbreak)
    # Same action, but keyed by nanoflow_name. 'objectId' is rejected here —
    # the id field is 'object_id' for both flow kinds.
    dbg add_breakpoint "{\"nanoflow_name\":\"${2:?need a nanoflow}\",\"object_id\":\"${3:?need an object id}\",\"condition\":\"${4:-}\"}" | pretty ;;
  unbreak)
    dbg remove_breakpoint "{\"object_id\":\"${2:?need an object id}\"}" | pretty ;;

  paused)   dbg get_paused_microflows '{}' | pretty ;;
  # Paused NANOFLOWS never appear in get_paused_microflows — they are delivered
  # as 'paused_microflow' events instead, so this is the only way to see one.
  events)   dbg poll_events '{}' | pretty ;;
  object)   dbg get_object "{\"debug_id\":\"${2:?need a debug id}\",\"variable_name\":\"${3:?need a variable}\"}" | pretty ;;
  list)     dbg get_list "{\"debug_id\":\"${2:?need a debug id}\",\"variable_name\":\"${3:?need a variable}\"}" | pretty ;;

  step)
    # NOTE for nanoflows: each step issues a NEW debug_id and invalidates the
    # one you stepped with, so re-read 'events' between steps. Microflow
    # debug_ids stay stable and can be reused.
    case "${2:-}" in
      over|into|out) dbg "step_$2" "{\"debug_id\":\"${3:?need a debug id}\"}" | pretty ;;
      *) echo "usage: $0 step over|into|out <debug-id>" >&2; exit 2 ;;
    esac ;;
  continue)
    if [ -n "${2:-}" ]; then dbg continue "{\"debug_id\":\"$2\"}" | pretty
    else dbg continue_all '{}' | pretty; fi ;;

  stop)     dbg stop_session '{}' | pretty; rm -f "$TOKEN_FILE" ;;

  *) sed -n '2,32p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' ;;
esac
