#!/usr/bin/env bash
#
# verify.sh — the project's gate: "did my change break anything?"
#
# Stage 1 is `mxcli verify`, which runs check (on any scripts given), lint and
# `mx check` against the baselines in Sudoku/verify-baseline/ and reports only
# findings that are NEW. This project carries 451 accepted lint findings, so a
# raw lint count is useless as a gate — only the delta against the baseline
# means anything. --fail-on warning is deliberate: the baseline already absorbs
# every standing warning, so any warning it reports is one this change added.
#
# Stage 2 is what `mxcli verify` does not cover and this project cares about:
#   - the page describe -> exec round trip, measured over two passes. Pass 1 is
#     cosmetic (how close the stored model is to the writer's normal form);
#     pass 2 is the number that matters, and 20 of 20 means every page is
#     losslessly expressible in MDL. See FINDINGS.md #67.
#   - the microflow describe -> check round trip.
#   - the 44 microflow unit tests.
#   - `mxcli brain check`.
#
# Usage:
#   scripts/verify.sh                   # gate the project as it stands
#   scripts/verify.sh a.mdl b.mdl       # also check those scripts (not applied)
#   scripts/verify.sh --apply a.mdl     # check, apply, then gate the result
#   scripts/verify.sh --quick           # stage 1 only (seconds, no mxbuild/tests)
#
# To accept the current state as the new baseline after a deliberate change:
#   mxcli verify -p Sudoku/Sudoku.mpr --update-baseline
# and commit Sudoku/verify-baseline/. It refuses to absorb new mx check errors
# unless you also pass --accept-errors.
#
# Exit status is mxcli verify's own (0 clean, 16+bits a stage failed: 1 check,
# 2 lint, 4 mxcheck, 8 exec), or 1 if a stage-2 check fails.
set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MPR="${PROJECT_DIR}/Sudoku/Sudoku.mpr"
TESTS="${PROJECT_DIR}/Sudoku/sudoku.test.mdl"

command -v mxcli >/dev/null 2>&1 || { echo "verify: mxcli not on PATH"; exit 1; }
[ -f "$MPR" ] || { echo "verify: no project at $MPR"; exit 1; }

QUICK=0
args=()
for a in "$@"; do
  case "$a" in
    --quick) QUICK=1 ;;
    *) args+=("$a") ;;
  esac
done

echo "== stage 1: mxcli verify (check / lint / mx check against the baseline)"
mxcli verify -p "$MPR" --fail-on warning ${args[0]+"${args[@]}"}
rc=$?
[ "$rc" -ne 0 ] && { echo "verify: the gate failed (exit $rc) — stopping before stage 2"; exit "$rc"; }

[ "$QUICK" -eq 1 ] && { echo "== stage 2 skipped (--quick)"; exit 0; }

fail=0
echo "== stage 2: round trips, tests, brain"

# Page round trip, two passes, in a scratch copy so the project is never written to.
# deployment/ is 23MB of build output that a running `mxcli run` rewrites under us,
# so copying it is both wasteful and noisy (files vanish mid-copy). tar, not rsync:
# rsync is not installed here — see FINDINGS.md #65 / ako/mxcli#1214.
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/p"
tar -cf - -C "${PROJECT_DIR}/Sudoku" --exclude=deployment --exclude=.mxcli . |
  tar -xf - -C "$work/p"
pages="$(mxcli -p "$work/p/Sudoku.mpr" -c "LIST PAGES" 2>/dev/null |
         awk -F'|' '/^\| [A-Za-z]+\./{gsub(/ /,"",$2);print $2}')"
total="$(printf '%s\n' "$pages" | grep -c .)"
pass() {
  local u=0 r=0 f=0 out
  while read -r p; do
    [ -z "$p" ] && continue
    mxcli -p "$work/p/Sudoku.mpr" -c "DESCRIBE PAGE $p" 2>/dev/null > "$work/d.mdl"
    out="$(cd "$work/p" && mxcli exec "$work/d.mdl" -p Sudoku.mpr 2>&1)"
    case "$out" in
      *"Unchanged page"*)                 u=$((u+1)) ;;
      *Error:*|*"Refusing to execute"*)   f=$((f+1)); echo "     REFUSED $p" ;;
      *)                                  r=$((r+1)) ;;
    esac
  done <<< "$pages"
  echo "$u $r $f"
}
read -r u1 r1 f1 <<< "$(pass)"
read -r u2 r2 f2 <<< "$(pass)"
echo "   pages          pass1 ${u1}/${total} unchanged, ${r1} rewritten, ${f1} refused"
echo "                  pass2 ${u2}/${total} unchanged, ${r2} rewritten, ${f2} refused"
if [ "$u2" -ne "$total" ] || [ "$f1" -ne 0 ] || [ "$f2" -ne 0 ]; then
  echo "   FAIL: every page must round-trip losslessly by pass 2 (FINDINGS.md #67)"
  fail=1
fi

# Microflow round trip: each flow's own description must check clean.
bad=0 n=0
for m in $(mxcli -p "$MPR" -c "LIST MICROFLOWS IN Sudoku" 2>/dev/null |
           awk -F'|' '/^\| Sudoku\./{gsub(/ /,"",$2);print $2}'); do
  n=$((n+1))
  mxcli -p "$MPR" -c "DESCRIBE MICROFLOW $m" 2>/dev/null > "$work/m.mdl"
  if mxcli check "$work/m.mdl" -p "$MPR" --references 2>&1 | grep -qE '✗|Parse error'; then
    bad=$((bad+1)); echo "     FAILED $m"
  fi
done
echo "   microflows     $((n-bad))/${n} round-trip"
[ "$bad" -ne 0 ] && fail=1

if out="$(mxcli test "$TESTS" -p "$MPR" --local --require-assertions 2>&1)"; then
  echo "   tests          $(printf '%s' "$out" | grep -E '^Total' | head -1)"
else
  echo "   tests          FAILED"; printf '%s\n' "$out" | grep -E '^Total|FAIL' | head -5
  fail=1
fi

if mxcli brain check -p "$MPR" >/dev/null 2>&1; then
  echo "   brain          OK"
else
  echo "   brain          FAILED"; fail=1
fi

[ "$fail" -eq 0 ] && echo "== verify: clean" || echo "== verify: FAILED"
exit "$fail"
