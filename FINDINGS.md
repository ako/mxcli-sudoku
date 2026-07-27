# mxcli / MDL findings

Issues and limitations hit while building this Sudoku app end to end in MDL —
domain model, a logic solver, a number pad, a dark theme, notes, undo/redo and a
completion page — against **mxcli `2a4494a`** (branch `main`) and **Mendix 11.12.1**.

**Verification pass (2026-07-25).** Every repro below was re-run against a build
of `main` + open PRs **#26, #27, #28, #29** (merge head `6f976d95`), side by side
with the pinned build, on a scratch copy of the project. Results are recorded per
entry; the summary table is at the end. Two of my original entries turned out to
be **my own misdiagnosis** and are corrected in place — #9 and, partly, #3.

Each entry has the symptom, a minimal repro, and the workaround actually used.
Severity is from the point of view of someone authoring an app with mxcli:

| | |
|---|---|
| **Bug** | mxcli accepts something Mendix rejects, or docs contradict behaviour |
| **Gap** | `mxcli check` passes, `mx check` fails — the pre-flight missed it |
| **Limitation** | Works as designed, but the design blocks a reasonable thing |
| **Docs** | Documentation is wrong or missing |

---

## 1. `randomInt()` is documented but does not exist

> **FIXED (docs), PR #28.** `write-microflows.md` now states "No `randomInt`. Mendix has no `randomInt` function. Use `random()`". The expression itself is still accepted by `mxcli check` and still fails at build — validating expression function names remains open.

**Bug / Docs / Gap.** `.ai-context/skills/write-microflows.md` lists
`randomInt($max)` under "Special Values". It parses, passes
`mxcli check --references`, and then fails at build:

```
[error] [CE0117] "Error(s) in expression." at Create variable activity
```

— once per use. Eight uses produced eight identical, location-free errors.

```mdl
declare $r integer = randomInt(9);      -- passes mxcli check, fails mx check
```

**Workaround:** `round(random() * 8)`. Note `random()` returns a Decimal, so the
`round()` is required for an integer target (see #2).

**Suggested fix:** drop `randomInt` from the skill docs, or implement it. Ideally
`mxcli check` would validate expression function names against the Mendix
expression grammar, which would catch this class of error before a build.

---

## 2. Decimal-returning functions assigned to integers (CE0117)

> **Open.** Not claimed by these PRs; `mxcli check` still passes `declare $n integer = secondsBetween(...)`.

**Gap.** Mendix `div`, `random()` and `secondsBetween()` all return Decimal.
Assigning to an `integer` variable is a build error, not a check error:

```mdl
declare $n integer = secondsBetween($a, $b);   -- CE0117 at mx check
declare $n integer = round(secondsBetween($a, $b));   -- fine
```

`div` is documented (MDL041). `random()` and `secondsBetween()` are not, and
`mxcli check` flags none of them. Hit twice in this build.

---

## 3. `not` before an attribute path does not parse

> **FIXED (diagnostics), PR #29 — and my original entry was partly wrong.** `not($Cell/"IsInvalid")` **parses on both builds**: the operator works, it just needs parentheses, which I never tried. The PR turns the old 3-screen token dump into: "Mendix requires parentheses around a negated expression … `if not($Cell/IsInvalid) then …` (correct)". So the real defect was the error message, and it is fixed.

**Bug.** Boolean negation of an entity path fails in the MDL grammar:

```mdl
if not $Cell/"IsInvalid" then    -- line N:15 missing THEN at '$Cell'
if $Cell/"IsInvalid" = false then  -- works
```

`not` is documented as a supported operator ("Boolean Logic" in
write-microflows.md), with `$Result = not $A;`. It appears to work only on plain
variables, not on paths. The error message points at the wrong token, which makes
this slow to diagnose.

---

## 4. `index ... on (...)` inside `create entity` does not parse

> **Open.** Still `extraneous input 'on' expecting '('`, still followed by the unrelated "unescaped apostrophe" hint.

**Bug / Docs.** `mdl-entities.md` documents entity indexes:

```mdl
create persistent entity M."Cell" ( ... )
index idx_cell_position on ("Row", "Col");
```

Result: `line N:24 extraneous input 'on' expecting '('`. No variation tried
(unquoted name, quoted name, `index ("Row")`) parsed. Indexes had to be dropped
from the model.

---

## 5. One `alter entity` accepts `default` only on its first `add`

> **FIXED, PR #28.** The multi-`add` repro now returns `✓ Syntax OK (2 statements) / Check passed!` where the pinned build reported `no viable alternative at input '9'`.

**Bug.** Multiple `add attribute` clauses in a single `alter entity` parse, but
only the first may carry a `default`:

```mdl
alter entity M."Game"
  add attribute "A": integer default 9,
  add attribute "B": integer default 9;    -- no viable alternative at input '9'
```

**Workaround:** one `alter entity` statement per attribute. This build needed 25
of them where 3 would have done.

---

## 6. `autonumber` without a default fails the build

> **PARTIALLY FIXED, PR #28.** `create entity` with a seedless autonumber is now caught at check time: `✗ autonumber attribute 'Code' has no seed — the build fails CE7247 [MDL023]`. But the `alter entity … add attribute "X": autonumber` path — the one this app actually used — still passes check, writes a seedless attribute, and fails `mx check` with CE7247.

**Gap / Docs.** Adding an autonumber and nothing else:

```mdl
alter entity M."Game" add attribute "PuzzleNo": autonumber;
```

passes `mxcli check` and fails `mx check` with
`[CE7247] "Value cannot be empty." at Attribute 'M.Game.PuzzleNo'`. The
autonumber needs a seed: `autonumber default 2831`. Not mentioned in
`mdl-entities.md`, which shows `CustomerNumber: autonumber` with no default.

---

## 7. `autocreateddate` silently renames the attribute, and is unbindable

> **FIXED, PR #28.** Now warns at check time with **MDL022**: "attribute 'StartedAt: AutoCreatedDate' is renamed to the fixed system member 'CreatedDate' on write — the declared name is discarded", plus the fix ("this is a Mendix system member and cannot be bound in a widget; use a plain attribute … and set it yourself"). Both halves of the trap are covered.

**Bug / Docs.** Two surprises in one attribute type. Declaring:

```mdl
create persistent entity M."Game" ( "StartedAt": autocreateddate );
```

produces an attribute called **`CreatedDate`** — the declared identifier is
silently discarded. `describe entity` then shows `CreatedDate: AutoCreatedDate`.

Worse, binding it in a widget fails the build:

```
[CE1613] "The selected attribute 'M.Game.CreatedDate' no longer exists."
   at Text 'sdPuzzleDate'
```

because `autocreateddate` maps onto Mendix's **system** `createdDate` member,
which is not a regular attribute a widget can bind. The error text ("no longer
exists") is actively misleading — the attribute does exist and `describe` shows it.

**Workaround:** declare an ordinary `datetime` and stamp it yourself
(`"DealtAt" = [%CurrentDateTime%]`).

---

## 8. XPath constraints reject arithmetic

> **Open (message improved).** Still a parse error; the new build appends `[see: mxcli syntax <topic>]`.

**Limitation.** A `where [...]` constraint cannot compute:

```mdl
retrieve $M from M."Move" where [... and "Seq" = $Game/"MoveSeq" + 1] limit 1;
-- line N:66 mismatched input '+' expecting ']'
```

**Workaround:** compute into a variable first, then compare against it. Fine once
known, but the failure is a parse error rather than a message about XPath.

---

## 9. `mxcli check --references` rejects same-file forward references

> **WITHDRAWN — my misdiagnosis.** A synthetic repro (caller in statement 1, callee in statement 2 of the same file) **passes on both builds**. Re-reading my session: the definitions had never been appended to the file — a guard in my own generator script misfired — so the microflows genuinely did not exist and the checker was right. The checker behaves as documented. Ordering files by dependency is still good practice, but it was not required here.

**Bug.** The docs state the reference checker "automatically skips references to
objects that are created within the same script". It does not — it appears to
resolve in file order, so a microflow that calls one defined **later in the same
file** is reported as missing:

```
- microflow not found: Sudoku.ACT_LogMove (referenced by call microflow)
```

even though `ACT_LogMove` is created by statement 8 of that same script.

**Workaround:** order definitions by dependency inside each file. Sensible
practice anyway, but it is not what the documentation promises.

---

## 10. Scripts are not re-runnable, and exec stops at the first error

> **Open — and the suggested remedy is dangerous, see #24.** `alter entity … add attribute` is still non-idempotent and `exec` still halts at the first error.

**Limitation.** `alter entity ... add attribute` fails if the attribute exists,
and there is no `add attribute if not exists` (nor `create or replace` for
entities/associations — only for microflows and pages). Because `exec` halts on
the first error, re-running a domain script that is 90% already-applied applies
**none** of the remaining 10%:

```
Error: attribute 'DateLabel' already exists on entity Sudoku.Game
```

**Workaround:** hand-split the delta into a scratch file and run that. A
`--continue-on-error` flag, or idempotent `add`, would make domain scripts
maintainable.

---

## 11. `alter page ... insert` is not idempotent either

**Limitation.** Re-running an ALTER that inserts a widget:

```
Error: failed to insert: duplicate widget name 'btnNew'
```

and if the anchor widget was removed by a later page rewrite:

```
Error: failed to insert: widget "btnReset" not found
```

There is no conditional insert and no `drop widget if exists`, so a page script
plus its ALTERs cannot be replayed without hand-editing.

---

## 12. `create or replace page` silently drops ALTER-added widgets

**Limitation (worth documenting).** Recreating a page discards anything a later
ALTER had inserted. Combined with #11 this makes "page + patch" pipelines
fragile: re-running the page script drops the patch, and re-running the patch
then fails or double-inserts depending on ordering.

---

## 13. Layering scripts lets an earlier file silently revert a later one

**Limitation / workflow hazard.** With `create or replace microflow`, keeping an
old definition in file A and an override in file B means re-running A silently
reverts B's version. That produced a build where the page bound
`ACT_ApplyValue(Cell)` while the pipeline had last written `ACT_ApplyValue(Game)`:

```
[CE1613] "The selected parameter 'Sudoku.ACT_Set4.Cell' no longer exists."
```

Nothing warns about it. The fix was structural — make script numbering the
dependency order and keep exactly one definition of each element.

---

## 14. Warm-loop: a page-structure change can leave the client bundle unbuilt

**Bug.** After a `create or replace page` that changes structure,
`mxcli run --local --watch` reported a successful reload while the browser 404'd
on the page's chunk:

```
[Client] An error occurred while loading page 'Sudoku.Game_Play' ...
  Failed to fetch dynamically imported module:
  http://127.0.0.1:8080/dist/pages/Sudoku.Game_Play.js   → 404
```

`mx check` was clean; the board simply never rendered. Restarting `mxcli run`
(forcing a full client bundle) fixed it every time. Hit twice.

---

## 15. Running `mxbuild` by hand wedges a live `mxcli run --watch`

> **IMPROVED, PR #28.** The warm loop now prints the serve response verbatim instead of only the generic message, so the real cause is visible. The underlying clash (two writers on `deployment/`) is unchanged.

**Limitation.** Both processes write `deployment/`. Running `mxbuild` manually to
read a SCSS compile error left the watch loop failing every subsequent build with:

```
build failed: The project cannot be deployed, because it contains errors.
```

while `mx check` reported **0 errors** — a misleading message pointing at the
model rather than the clash. Recovery: stop the loop, delete `deployment/model`
and `deployment/web`, restart.

**Suggestion:** `mxcli run` could detect a foreign writer, or surface the real
mxbuild error rather than the generic "contains errors".

**Seen again from `mx check`, not just `mxbuild`.** Running the validator while
the loop was live produced a build failure whose only Error entry was
`"Could not check expression. Checking will resume after the next change."` —
the serve process had been knocked out of a consistent state by the other
reader. The raw output being surfaced (the PR-build improvement above) is what
made that diagnosable at all. Recovery is cheaper than the original: touch any
source file and let the next build go through. Worth knowing that `mx check` is
a foreign writer too, since it looks read-only.

---

## 16. `mxcli run --hub` registers once and never re-registers

> **FIXED, PR #27.** `runlocal.go` now runs a heartbeat that re-registers on a hub restart and restarts the tunnel if the reverse port moved, printing "Re-registered with hub after restart; preview available at …". Covered by a new unit test (`hubclient_reregister_test.go`), which passes. Not re-tested end to end, since that needs the hub restarted.

**Bug.** The chisel transport reconnects on its own — the log shows 26 failed
attempts then `Connected` — but the hub **registration** is sent only at startup
(`grep -c "Registering with hub"` → 1 for a whole session). So after the hub
restarts, the tunnel looks healthy locally while the hub lists no session and the
public URL returns nothing.

This is hard to diagnose because the local side reports success. The symptom for
a user is "the page loads but every action fails" (static assets cached, `/xas/`
unreachable).

**Suggestion:** re-send the registration on each successful reconnect.

---

## 17. `mxcli run` requires an absolute `-p` path

> **FIXED, PR #28.** Verified end to end: `mxcli run --local -p Sudoku/Sudoku.mpr` from the parent directory boots the app on the new build; the pinned build fails with "the project file path should be an absolute path".

**Limitation / message quality.** A relative path fails with MxBuild's raw error
plus a Windows-flavoured JSON sample:

```
Error: initial build failed: the project file path should be an absolute path.
{ "sampleRequestModels": [ { "projectFilePath": "C:\\Users\\..." } ] }
```

mxcli could simply resolve the path before handing it to MxBuild.

---

## 18. Widgets cannot take a dynamic inline style

**Limitation (Mendix, worked around in MDL).** `Style:` is static and
`DynamicClasses:` returns class names, so anything with a computed dimension —
a progress bar, a bar chart — needs a class per discrete step. Both are done here
by publishing a 0..20 bucket from a microflow and generating 21 CSS classes:

```scss
@for $i from 0 through 20 { .sd-pb-#{$i} { width: $i * 5%; } }
```

Workable, but worth documenting as the idiom, since it constrains the domain
model (an extra bucket attribute per animated dimension).

---

## 19. Buttons cannot pass literal arguments, and cannot hold rich content

**Limitation (Mendix).** Two separate constraints that together shape the design:

- A button can only map **object** parameters from the page context, so a
  9-key number pad needs nine wrapper microflows (`ACT_Set1`…`ACT_Set9`) over one
  real implementation.
- An `actionbutton` cannot contain child widgets, so a key showing a digit over a
  "4 LEFT" label has to be a `container` with `OnClick:` instead.

`container (OnClick: microflow M.ACT_X(Param: $currentObject))` works well and is
the more flexible primitive — worth promoting in `create-page.md`, which
currently documents `OnClick` only in passing.

---

## 20. Attributes cannot be indexed from a widget, forcing wide entities

**Limitation.** Pencil marks are nine booleans per cell (`N1`…`N9`) rather than
one packed string, purely because a widget cannot index into a string and each
mark needs its own visibility expression. That also makes the toggle microflow a
nine-branch `if` chain. A packed representation would be far cleaner server-side
but unrenderable client-side.

---

## 21. `mxcli lint` MPR008 is unusable on generated microflows

**Limitation.** MDL auto-positions activities on the Studio Pro canvas; loop-heavy
microflows overlap and produce a wall of warnings (27 for one microflow):

```
⚠ Activities '(unnamed)' (1190,80) and '(unnamed)' (1190,80) overlap ...
   Each MDL statement that creates a canvas activity needs its own @position
```

Requiring a hand-written `@position` per statement is not viable for a 200-line
generated microflow. Auto-layout on write, or suppressing the rule for
MDL-authored flows, would help.

---

## 22. Documentation says SCSS partials cannot be created

**Docs.** `migrate-design-prototype.md` states the agent "generally **cannot**
create new SCSS partials (only existing files are writable)" and that all custom
styles must go inline in `main.scss`. In practice creating
`theme/web/_sudoku.scss` and adding `@import "sudoku";` to `main.scss` worked
fine and keeps the theme far more readable. The guidance appears stale.

---

## 23. Theme compile errors surface late and generically

> **FIXED, PR #28.** Verified end to end on a scratch copy: injecting a bad SCSS rule now yields the compiler's own message in the watch loop — `Error: Expected expression.`, the offending source line with a caret, and `_sudoku.scss 768:34`. The pinned build printed only `build failed: An error occurred while compiling Theme files`.

**Limitation.** A SCSS error is reported by the watch loop only as:

```
build failed: An error occurred while compiling Theme files
```

with no file or line. Getting the real message (`Expected expression.
_sudoku.scss 180:35`) required running `mxbuild` by hand — which then caused #15.
Surfacing the compiler's own message in the watch output would remove that trap.

---

---

## 24. `CREATE OR MODIFY` is suggested for "already exists" — and silently deletes attributes

**Bug (data loss).** Re-running a create-only script produces:

```
statement 4: entity already exists in project: Sudoku.Game
             — use CREATE OR MODIFY to update it
```

Following that advice with anything less than the entity's **complete** attribute
list replaces the attribute set rather than merging it. On a partial definition:

```mdl
create or modify persistent entity Sudoku."Game" (
  "Level": Sudoku."Difficulty" default Easy,
  "ProbeReRun": integer default 7
);
```

`Sudoku.Game` went from **36 attributes to 2**, and `mx check` went from 0 errors
to **55**, all `CE1613 "... no longer exists"` across every microflow and page that
referenced a dropped attribute. On a project with data, those are dropped columns.

Present in both the pinned and the PR build. The hazard is the pairing: the error
text recommends the command, and the command is destructive unless the script
happens to be the entity's full definition. Either the message should say
"redefines the entity — list every attribute", or the command should merge.

**Workaround used in this project:** never re-run `01`/`02`; extract the delta into
a scratch file and apply that.

---

## 25. `mxcli run --local` swallows the Mendix runtime log

**Gap.** The warm loop prints its own progress — build, reload, hub connection —
but the runtime's own log never surfaces anywhere a developer can read it:

- The runtime's stdout and stderr are a pipe consumed by `mxcli`
  (`/proc/<runtime-pid>/fd/1 -> pipe:[…]`, same inode for fd/2), so redirecting
  `mxcli run` to a file captures mxcli's lines only.
- `~/.mxcli/logs/mxcli-<date>.log` is a structured record of MDL sessions
  (`session_start`, `execute`, `session_end`). Zero runtime lines.
- `run` has no `--log-file`, `--verbose` or log-level flag.
- The M2EE admin API on 8090 answers `runtime_status` (`running`) with the local
  password, but `get_log_messages` returns `{"result":-5,"message":"Action not
  found."}`.

So when a microflow throws server-side, the browser shows the generic Mendix
error dialog and there is **nothing to correlate it against** — no stack trace,
no log node, no `LOG ERROR` output from your own microflows either. Debugging
falls back to reproducing in the client and reading the `/xas/` response bodies
off a Playwright page, which is a poor substitute for a stack.

This cost real time on an "error when selecting a cell" report: the whole
server side had to be excluded by other means (driving the UI, and querying
PostgreSQL directly) before the cause turned out to be client-side.

**Ask:** tee the runtime's stdout to `<project>/.mxcli/runtime.log` — or add
`--runtime-log <path>`. The pipe is already being read; writing it through costs
almost nothing and makes the warm loop debuggable.

### Retested against PR #38 (`6d3cde89`) — tee landed, **but the app log is not on stdout**

The tee itself works exactly as asked: `run` announces
`Runtime log: <projectDir>/.mxcli/runtime.log` at boot, creates the file, appends
across restarts behind a `=== runtime start <ts> ===` marker, and `--runtime-log`
overrides the path (`-` disables). `go test ./cmd/mxcli/docker/...` passes.

What it captures is only what the JVM writes to fd 1/2 — four lines:

```
=== runtime start 2026-07-26T05:39:55Z ===
Picked up JAVA_TOOL_OPTIONS: …
[rtlauncher:container$] INFO Container start took 6182. Ready to accept admin requests.
```

The **Mendix application log is not on stdout at all.** It is delivered to log
subscribers, and the standalone runtime boots with none attached. Proof: a probe
copy of `ACT_SelectCell` with `log info|warning|error node 'ProbeNode' …`, driven
by a real click — **0 lines** in `runtime.log`. Then a forced runtime exception
(`change` on an empty object) — also **0 lines** in `runtime.log`, while the
browser showed the generic "An error occurred, please contact your system
administrator."

Attaching a subscriber by hand puts everything where it was wanted:

```bash
curl -H "X-M2EE-Authentication: $(printf 'mxcli-local-dev' | base64)" \
     -H 'Content-Type: application/json' -d '{"action":"create_log_subscriber",
       "params":{"name":"file","type":"file","autosubscribe":"INFO",
                 "filename":"…/.mxcli/runtime.log"}}' http://127.0.0.1:8090/
```

and the same click then yields the log nodes *and* the microflow stack, pinned to
the exact activity:

```
INFO    - ProbeNode: MXCLI-PROBE-INFO selection flow entered
WARNING - ProbeNode: MXCLI-PROBE-WARN selection flow entered
ERROR   - ProbeNode: MXCLI-PROBE-ERROR selection flow entered
ERROR   - Connector: … Change object 'Some(Nothing)' should not be null
            at Sudoku.ACT_SelectCell (Change : 'Change 'Nothing' (IsSelected)')
          com.mendix.modules.microflowengine.MicroflowException: …
```

**Remaining ask:** call `create_log_subscriber` once during boot, right beside the
existing `update_configuration` call in `localboot.go`, pointing at the same
`RuntimeLogPath`. One caveat: `create_log_subscriber` with no params returns a
bare `JSONException`, so the params are required. `get_log_messages` is still not
an action on this runtime, so the subscriber — not polling — is the route.

Keeping the stdout tee is still worth it: JVM-level failures (OOM, a runtime that
dies before the admin API is up) never reach a subscriber.

### Retested against PR #39 (`a2f8d823`) — the subscriber is registered but never started

`Start` now calls `create_log_subscriber` with
`{type: file, name: mxcli-run-local, autosubscribe: INFO, filename: <abs RuntimeLogPath>, max_size: 1GiB, max_rotate: 0}`, on every start so a restarted JVM
is re-attached, best-effort so a logging failure can't fail the boot.
`go test ./cmd/mxcli/docker/...` passes.

It still captures nothing. On a fresh boot, `runtime.log` holds the same four
stdout lines, and driving a click through a probe microflow carrying
`log info|warning|error node 'ProbeNode' …` adds **0 lines**.

The missing call is `start_logging`. A standalone runtime boots with logging
**not started**, so a registered subscriber sits inert. Isolated on one boot:

| step | probe lines in `runtime.log` |
|---|---|
| boot (mxcli attaches its subscriber), then click | **0** |
| `start_logging` → `{"feedback":{},"result":0}`, then click | **6** |

Nothing else changed between the two rows. After that call the file gets the log
nodes *and* a server-side failure in full — `ERROR - Connector: … Change object
'Some(Nothing)' should not be null / at Sudoku.ACT_SelectCell (Change : …)`
followed by the `MicroflowException` stack.

**Correction to the note above, which is what sent this the wrong way.** I wrote
that `start_logging` must not be called because it throws `LoggingException:
Logging has already been started.` That was wrong. Logging is *not* running on a
fresh runtime; I had probed `start_logging` bare a moment earlier in the same
session, and my second call was what threw. On a fresh JVM the first call
succeeds with `result: 0`.

So `attachFileLogSubscriber` needs one more `CallM2EE(c.opts, "start_logging",
nil)` after the subscriber is created — treating an "already been started" error
as success, since `Start` also runs on paths where the JVM is not fresh.

### FIXED, PR #41 (`5fb58dbf`) — verified end to end

`configureRuntimeLogging` now calls `create_log_subscriber` then `start_logging`.
On a clean boot `runtime.log` fills immediately, and it turns out to capture the
**whole startup sequence**, not just what follows the call — the runtime buffers
its log until logging starts, then replays:

```
=== runtime start 2026-07-26T06:57:32Z ===
[rtlauncher:container$] INFO Container start took 4536. …
06:57:38.358 INFO - Core: Mendix Runtime 11.12.1 (build 11.12.1). …
06:57:38.391 INFO - Configuration: updateConfiguration: ApplicationRootUrl=…
06:57:41.401 INFO - ConnectionBus: Database product information: PostgreSQL 16.13
```

Re-running the two probes with **no manual admin call** at any point:

| probe | result |
|---|---|
| `log info/warning/error node 'ProbeNode'` in `ACT_SelectCell`, one click | all three lines, at the right levels |
| `change` on an empty object, one click | `ERROR - Connector: … Change object 'Some(Nothing)' should not be null` + `at Sudoku.ACT_SelectCell (Change : 'Change 'Nothing' (IsSelected)')` + the `MicroflowException` stack |

The restart path holds too, which is the case the code explicitly claims. Adding
an attribute to `Sudoku.Game` forced `build … applied via restart`; the second
`=== runtime start ===` marker appeared, no "application log not attached"
warning, and a click after the restart logged all three probe lines. Finding #25
is closed: a server-side failure in the warm loop is now diagnosable from one
file.

**One cosmetic follow-up.** The "already started" tolerance matches on the
substring `already`, but that word is not in the response. A second
`start_logging` against a live runtime returns:

```json
{"result": 1,
 "cause":   "class com.mendix.logging.LoggingException occurred while executing an admin action request. See logging output for details.",
 "message": "class com.mendix.m2ee.api.internal.AdminException occurred …"}
```

`M2EEError()` prefers `cause`, so the guard misses and `Start` prints
`(runtime application log not attached: start_logging: class
com.mendix.logging.LoggingException …)` on any re-`Start` against a still-running
JVM — the DB-update retry path named in the comment. Harmless (it is best-effort,
and logging is in fact attached), but the warning is spurious and says the
opposite of the truth. Matching `logging.LoggingException`, or just not warning
when `create_log_subscriber` itself succeeded, would close it.

---

## 26. The microflow debugger works from the shell, but mxcli exposes none of it

**Gap / opportunity.** The runtime ships a full interactive debugger — breakpoints,
paused flows, variable inspection, stepping — and `mxcli run --local` never
mentions it. `grep -ri "debugger\|breakpoint" *.go` in the mxcli tree returns
nothing outside a docs aside. It is reachable today, so this is a wiring gap
rather than a missing capability. Everything below was driven against the live
Sudoku app.

**Two APIs, and that is the part that is not obvious.** The M2EE admin API on
:8090 only switches the debugger on and off:

| action | params | result |
|---|---|---|
| `get_debugger_status` | — | `{number_of_paused_microflows, client_connected, enabled}` |
| `enable_debugger` | `{"password": "…"}` | `result: 0` — bare call fails with a `JSONException` |
| `disable_debugger` | — | `result: 0` |

Breakpoints live somewhere else entirely: the runtime serves a **second endpoint
at `<app>/debugger/`** — the one Studio Pro drives. It 401s until you send

```
X-Debugger-Authentication: base64(<the password passed to enable_debugger>)
```

Raw password, `Basic`, and `Bearer` all 401; the body of a 401 is `{}`, with no
`WWW-Authenticate`, so the scheme is not discoverable by probing. I read it off
`DebuggerConstants$` and `DebuggerHandler` in
`com.mendix.mxruntime.jar` with `javap`.

**The protocol.** `POST` `{action, session_token, params}`; replies are
`{result, status, message}` with `status: 0` for success and `2` for an error.

```
start_session {breakpoints:[]}      -> {session_token, runtime_version, project_id, paused_microflows}
add_breakpoint {microflow_name, object_id, condition}
remove_breakpoint {object_id}
get_paused_microflows {}            -> paused flows, each with every variable in scope
get_object {debug_id, variable_name} / get_list / get_object_from_list
step_over | step_into | step_out {debug_id}
continue {debug_id} | continue_all {}
poll_events {} | execute {…} | stop_session {}
```

Three details cost time and are worth writing down:

1. `params` is mandatory even when empty — `get_paused_microflows` without it
   answers `Missing property: params`.
2. `add_breakpoint` takes the breakpoint's fields **flat in `params`**, not
   nested under a `breakpoint` key, despite `BREAKPOINT` existing as a constant.
   Nested gives the unhelpful `Invalid breakpoint`.
3. `object_id` is the **model GUID of the activity**, and nothing in the runtime
   will tell you what it is. A wrong one at least fails loudly:
   `Microflow object with object id '…' not found in microflow 'Sudoku.ACT_SelectCell'`.

That third point is where mxcli already holds the missing piece. The GUIDs are in
the `.mpr`, and `mxcli bson dump -t microflow -o <flow>` prints them — as
little-endian .NET GUIDs, so `uuid.UUID(bytes_le=…)`:

```
09a75aa2-64d4-425b-84a9-24e82541d2b2  ActionActivity
369e5ece-6b4f-464a-a6c7-5703bcfb26fa  ExclusiveSplit    $Game = empty
d9bbc0f9-1386-4ad0-b627-78370a595bab  ActionActivity
```

**Verified end to end.** Breakpoint on the retrieve in `Sudoku.ACT_Hint`, `Hint`
clicked in a browser, flow paused:

```
stopped at Sudoku.ACT_Hint -> RetrieveByXPath
variables : $gatewayOutput, Game, Revealed, currentDeviceType, currentSession, currentUser
get_object Game -> PuzzleNo 2934, Level Easy, FilledCount 50, EmptyCount 31, HintCount 0
step over -> now at Gateway, and 'Empty' has appeared in scope
continue_all -> the trace log resumes and the click completes
```

`scripts/mfdebug.sh` in this repo wraps the whole flow (`enable`, `session`,
`activities`, `break`, `paused`, `object`, `step`, `continue`, `disable`).

**Ask:** an `mxcli debug` command. mxcli already owns both halves — the admin
password and app URL from `run --local`, and the activity GUIDs from the model —
so it is the only tool that can offer breakpoints **by name** (`mxcli debug break
Sudoku.ACT_Hint --activity 3` or `--caption '$Game = empty'`) instead of by
GUID. That is the whole difference between this being usable and being a curiosity.

**Caveat worth surfacing in any such command:** a breakpoint pauses *whoever*
hits it, including a real user in a browser, and the request just hangs. Anything
that sets one should make `continue`/`disable` obvious, and `run --local` should
disable the debugger on shutdown so a stray breakpoint cannot outlive the session.

---

## 27. An unreachable hub takes the whole app down with it

**Bug.** `mxcli run --hub <url>` treats hub registration as fatal. With the hub
host down, the launch aborts:

```
Starting incremental web client bundler...
Registering with hub https://hub.mxcli.org...
Error: hub registration: contacting hub: Post "https://hub.mxcli.org/api/register":
       net/http: TLS handshake timeout
```

No runtime, no local app — `curl 127.0.0.1:8080` gives nothing. The tunnel is a
*convenience* on top of a local run, so losing it should cost the preview URL and
nothing else.

The odd part is that mxcli already handles this correctly once running: when the
hub died mid-session at 07:46:44, the chisel client logged
`websocket: close 1006` and retried every 30s indefinitely while the local app
kept serving. Only registration *at startup* is fatal.

**Ask:** warn and continue local-only when the initial registration fails, then
retry in the background on the schedule the client already uses. Re-print the
preview URL if it succeeds later.

**Workaround:** drop `--hub` and run `mxcli run --local …`.

---

## 28. Nanoflow logging and debugging both work — with two traps

**Docs / Gap.** Nothing in the skill docs says where a nanoflow's `log` output
goes, or that nanoflows can be debugged at all. Both work; neither behaves the
way the microflow experience suggests.

### Logging: the declared node is discarded

`log info node 'Sudoku' 'NF_ToggleNotes';` inside a nanoflow reaches **two**
places. The browser console gets it, wrapped, along with free per-execution
timing:

```
debug: [Nanoflow] [flow_ojr_92] Starting execution of nanoflow Sudoku.NF_ToggleNotes.
info:  [Nanoflow] NF_ToggleNotes
debug: [Nanoflow] [flow_ojr_92] Finished execution of nanoflow Sudoku.NF_ToggleNotes. Execution took 6.7 milliseconds.
```

And it reaches the server log — but under the node **`Client_Nanoflow`**, not
the node the script declared:

```
22:51:00.357 INFO - Client_Nanoflow: NF_ToggleNotes     <- nanoflow, node rewritten
22:50:54.441 INFO - Sudoku: ACT_Refresh                 <- microflow, node kept
```

So any log filter built around microflows silently drops every nanoflow line.
`scripts/trace.sh` here now matches `Sudoku|Client_Nanoflow`. Either the runtime
should keep the declared node, or the docs should say it does not.

Measured cost: forwarding those lines used **0 HTTP requests** during the
interaction. They ride the already-open **`ws://…/mxdevtools/` websocket** —
confirmed by reading the frames, four of which carried the probe payload:

```
WS FRAME carries NFPROBE   x4      (debug, info, warning, error)
ws frames sent during the toggle: 6
```

So a nanoflow's log reaching the server log is a **dev-tools artefact**. With
dev tools off — any production build — expect the browser console and nothing
else. Anything built on `Client_Nanoflow` lines is a development-only facility.

**Levels: `debug` is sent but dropped.** All four levels leave the client, and
the level survives for three of them; the server discards `debug`:

| in the nanoflow | browser console | server log |
|---|---|---|
| `log debug` | `debug [Nanoflow] NFPROBE-DEBUG` | **absent** |
| `log info` | `info …` | `INFO - Client_Nanoflow: NFPROBE-INFO` |
| `log warning` | `warning …` | `WARNING - Client_Nanoflow: …` |
| `log error` | `error …` | `ERROR - Client_Nanoflow: …` |

Use `info` and up in a nanoflow if you want it in `runtime.log`; `debug` is
browser-only even though the client does put it on the wire.

### Debugging: paused nanoflows are invisible to the obvious call

Nanoflow breakpoints go through the same `<app>/debugger/` endpoint and the same
`add_breakpoint` action as microflows (#26), keyed by `nanoflow_name`:

```json
{"action":"add_breakpoint","session_token":"…",
 "params":{"nanoflow_name":"Sudoku.NF_ToggleNotes","object_id":"<activity GUID>","condition":""}}
```

The id field is still `object_id` for both flow kinds. Using `objectId` — which
*is* a real constant in `DebuggerConstants$`, bound to `NANOFLOW_OBJECT_ID` —
fails with a leaked NPE: `Invalid breakpoint:Cannot invoke "String.length()"
because "name" is null`.

**The trap:** a paused nanoflow **never appears in `get_paused_microflows`**.
That action keeps returning `{"paused_microflows": []}` while the browser sits
frozen mid-flow. Paused nanoflows are delivered as *events*:

```
poll_events -> {"events":[{"type":"paused_microflow","data":{
   "debug_id":"5528e595-…","microflow_name":"Sudoku.NF_ToggleNotes",
   "object_id":"d5399b09-…","variables":{"Game":{…,"entity":"Sudoku.Game"},
                                         "Mode":{"type":"boolean","value":true}}}}]}
```

— note the event type is still `paused_microflow` even for a nanoflow. Without
knowing to poll, the only symptom is a browser that stops responding and a
console that logged `Starting execution` with no matching `Finished`.

Everything downstream then works on that `debug_id`: `get_object` expanded the
client-side `Game` (`EmptyCount 31`, `Message`, …), and `continue` released the
browser — the console closed the flow with
`Finished execution … took 13331.8 milliseconds`, i.e. exactly the pause.
`get_debugger_status.client_connected` flips to `true` once a browser attaches,
which is the only hint that nanoflow debugging is live at all.

**Second trap: a nanoflow's `debug_id` is single-use.** Stepping works, but every
step **issues a new `debug_id`** and invalidates the old one. Microflows behave
the opposite way. Same script, same `step over`, run three times:

```
nanoflow   e82ddd93 at 2ccf6e32 -> 8b586465 at 1e458f73 -> 3a6ea730 at 2467b992 -> 92008581 at 9928f9b9
microflow  dec595f0 at RetrieveByXPath -> dec595f0 at Gateway -> dec595f0 at Change
```

Reusing the id you stepped with fails on the *second* step with
`Could not find microflow/nanoflow in debug with id: …`, which reads like the
flow ended rather than like a stale handle. Any tool that caches the id across
steps — the obvious design, and what a microflow lets you get away with — breaks
after one step on a nanoflow. Re-read `poll_events` between steps.

`scripts/mfdebug.sh` covers both: `nactivities`, `nbreak`, and `events`.

### Why it mattered here

Replacing one microflow with a nanoflow (`ACT_ToggleNotes` → `NF_ToggleNotes`),
measured over four toggles each:

| | round trips | bytes | click → UI updated |
|---|---|---|---|
| microflow | 2 | ~37 KB | ~140 ms |
| nanoflow | **0** | **0** | **~73 ms** |

The 37 KB was the gallery refetching all 81 squares because the Game was
committed with `refresh` — to flip one boolean. The nanoflow deliberately does
**not** commit, and the mode still reaches the server: Mendix sends an object's
uncommitted client state along when a later microflow takes it as a parameter,
which was verified by toggling notes and then writing a pencil mark through the
server-side `ACT_ApplyValue`.

---

## 29. OpenTelemetry is all there, and `mxcli run --local` can reach none of it

**Gap.** The runtime ships everything needed for metrics and traces. Neither is
reachable through `mxcli run --local`, for two different reasons — and both are
one small change away.

### Metrics: present, registered, and switched off

The admin port already mounts the servlet at boot:

```
INFO - M2EE: Added admin request handler '/prometheus' with servlet class
       'com.mendix.metrics.prometheus.PrometheusServlet'
```

but it answers **`503 No PrometheusMeterRegistry available`**, because no
registry is configured. The settings that configure one — `Metrics.Registries`
and `Metrics.ApplicationTags`, found in `com.mendix.configuration.jar` and
`com.mendix.metrics.jar` — take effect on a **live** `update_configuration`, no
restart:

```json
{"action":"update_configuration","params":{
  "…the settings mxcli already sent…",
  "Metrics.Registries":[{"type":"prometheus","settings":{"step":"PT10S"}}]}}
```

and `/prometheus` immediately serves **71 metric families**. Registry types
available from the bundled Micrometer: `prometheus`, `otlp`, `influx`, `statsd`,
`jmx`.

The Mendix-specific ones are the interesting part — a live instrument for
exactly the optimisation work in #28:

```
connectionbus_selects_total, _inserts_total, _updates_total, _deletes_total,
connectionbus_transactions_total, handler_requests_total,
sessions_anonymous_sessions, taskqueue_*
```

One deal plus five square selections moved them by **+162 selects, +21 updates,
+7 inserts, +89 transactions** — the measurement that previously needed
`pg_stat_user_tables`.

**Why mxcli blocks it:** `runtimeConfigParams` in `localboot.go` builds a fixed
map (BasePath, RuntimePath, DTAPMode, the DB fields, MicroflowConstants,
ApplicationRootUrl) with no passthrough for anything else. And
`update_configuration` **replaces** rather than merges, so setting metrics by
hand means repeating every value mxcli sent or the runtime loses its database
connection. There is no `get_configuration` action to read them back from.

**Ask:** a `--runtime-setting Key=Value` (repeatable) on `mxcli run`, or simply
`--metrics` to register Prometheus. Either removes the need to reconstruct the
whole config.

### Traces: the agent ships with the runtime, but nothing can load it

The runtime bundles the OTel **API** only — `opentelemetry-api`, `-common`,
`-context`, `-proto`. No SDK, no exporter. The implementation is a Java agent
sitting unused in the runtime tree:

```
/root/.mxcli/runtime/<version>/runtime/agents/opentelemetry-javaagent.jar   (24 MB, v2.28.1)
```

`mxcli` spawns the JVM as `exec.Command(javaExe, "-jar", launcherJar, deployDir)`
— **no JVM arguments, and no flag to add any**. The only way in is
`JAVA_TOOL_OPTIONS` on the mxcli process, which the JVM inherits:

```bash
export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:-} -javaagent:…/opentelemetry-javaagent.jar"
export OTEL_SERVICE_NAME=sudoku OTEL_TRACES_EXPORTER=console \
       OTEL_METRICS_EXPORTER=none OTEL_LOGS_EXPORTER=none
```

Append, never replace — this sandbox already uses `JAVA_TOOL_OPTIONS` for its
TLS proxy. With `OTEL_TRACES_EXPORTER=console` the spans land in
`.mxcli/runtime.log` via the tee from #25, so **no collector is needed** to see
whether tracing works.

It works, and Mendix instruments deeply — `tracer: com.mendix.runtime`, with
`mx.microflow.name` and `mx.microflow.depth` attributes:

```
'Microflow Sudoku.ACT_SelectCell' : 5d2155108ea0fcd9… 1f8dfee0da6ac67f SERVER
  [tracer: com.mendix.runtime:] AttributesMap{data={mx.microflow.depth=1,
  mx.microflow.name=Sudoku.ACT_SelectCell, …}}
```

### The trap: default tracing is per-activity, and that is unusable

Every microflow activity becomes a span. **One board deal produced ~110,000
spans**:

```
62566  CreateOrChangeVariable activity
22638  Loop iteration
18260  Gateway activity
 5505  Loop activity
    4  Microflow Sudoku.ACT_SolveGrid
```

The deal went from ~0.1-0.5 s to **5.8 s**. Any real collector would be buried.

The fix is an undocumented runtime setting, `OpenTelemetry._RuntimeSpanFilters`
(the leading underscore is real — from `OpenTelemetryConfig`), a list of span
**name prefixes to suppress**:

```json
"OpenTelemetry._RuntimeSpanFilters": ["CreateOrChangeVariable","Loop","Gateway","RetrieveFromCache"]
```

Same deal, same agent: **404 spans instead of ~110,000**, and 0.27-0.59 s
instead of 5.8 s. What survives is what you actually want — microflow spans,
commits, JDBC statements, HTTP requests. It applies live, like the metrics.

| | spans per deal | deal time |
|---|---|---|
| no agent | — | 0.09-0.54 s |
| agent, default | ~110,000 | 5.77 s |
| agent + filters | 404 | 0.27-0.59 s |

**Ask:** ship those filters as the default, or at least document the setting
next to the tracing docs — per-activity spans are a debugging mode, not a
production default, and the only signal that something is wrong is the app
becoming ten times slower.

`scripts/otel.sh` in this repo wraps all of it: `configure`, `metrics`, `raw`,
`agent-env`, `spans`, `trace`.

### FIXED, PR #46 (on `main` at `3e9a1027`) — verified end to end

`run` gained `--metrics`, `--trace`, `--trace-service` and a repeatable
`--runtime-setting Key=Value`. Both features are **opt-in**: a plain
`mxcli run --local` still answers `No PrometheusMeterRegistry` and attaches no
agent, which is right — tracing costs real time.

| what was asked | what landed | verified |
|---|---|---|
| a way to pass runtime settings | `--runtime-setting Key=Value`, value JSON-parsed, repeatable | filter list below |
| register Prometheus without hand-rebuilding the config | `--metrics` | `/prometheus` serves **71 families** at boot, and `run` prints `Metrics (Prometheus): http://127.0.0.1:8090/prometheus` |
| load the bundled agent | `--trace` | `opentelemetry-javaagent 2.28.1` in the runtime log |
| ship the span filters as the default | `--trace` applies them | **433 spans / 0.92 s** per deal, against ~110,000 / 5.77 s unfiltered |

Three details the PR got right that are easy to get wrong:

1. **`JAVA_TOOL_OPTIONS` is appended, not replaced.** The runtime's environment
   still carries this sandbox's TLS proxy settings *and* the agent:
   `trustStore=/root/.ccr/java-truststore.p12 … -javaagent:…/opentelemetry-javaagent.jar`.
   Overwriting would have broken outbound TLS.
2. **Your `OTEL_*` wins.** `OTEL_SERVICE_NAME` defaults to the `.mpr` name
   (`Sudoku`), but exporting `OTEL_SERVICE_NAME=my-own-name` before launching
   left it untouched — so pointing at a real OTLP collector instead of the
   console exporter still works.
3. **An explicit filter list overrides the default.** Adding
   `--runtime-setting 'OpenTelemetry._RuntimeSpanFilters=[…,"Change","ChangeList","CreateAndChange"]'`
   dropped those span families too: **221 spans** instead of 433.

`go test ./cmd/mxcli/docker/...` passes. `scripts/otel.sh` is now mostly
redundant — `configure` and `agent-env` are replaced by the flags; `metrics`,
`spans` and `trace` are still handy as readers.

---

## Verification summary

Build under test: `main` (`2a4494ac`) + PRs #26, #27, #28, #29 → `6f976d95`.
`go test ./mdl/visitor/... ./mdl/executor/... ./cmd/mxcli/docker/...` passes.
Finding 25 was retested later against `main` at `6d3cde89` (PR #38),
`a2f8d823` (PR #39) and `5fb58dbf` (PR #41, where it closed).

| # | Finding | Status |
|---|---|---|
| 1 | `randomInt()` documented but absent | Docs fixed; check still accepts it |
| 3 | `not` before a path | Fixed (message) — original entry partly wrong |
| 5 | multi-`add` with defaults | **Fixed** |
| 6 | autonumber seed | Partial — `create` caught, `alter … add` not |
| 7 | `autocreateddate` rename / unbindable | **Fixed** (MDL022) |
| 9 | same-file forward references | **Withdrawn — my misdiagnosis** |
| 15 | mxbuild clash reported generically | Improved (raw output surfaced) |
| 16 | hub registered once only | **Fixed** (heartbeat re-register) |
| 17 | relative `-p` on `run` | **Fixed** |
| 23 | theme errors generic | **Fixed** |
| 2, 4, 8, 10–14, 18–22 | — | Open / not claimed |
| 24 | `CREATE OR MODIFY` deletes attributes | **New** |
| 25 | runtime log unreachable from `run --local` | **Fixed** (#38, #39, #41) — verified end to end |
| 26 | microflow debugger not exposed by mxcli | **New** — protocol mapped, driven end to end |
| 27 | unreachable hub aborts the whole run | **New** |
| 28 | nanoflow log node rewritten; paused nanoflows only in `poll_events` | **New** |
| 29 | OTel metrics/traces unreachable from `run --local`; per-activity spans unusable | **Fixed** (#46) — `--metrics` / `--trace` / `--runtime-setting` |

The app's own pipeline (`03`–`08`) checks clean through the PR build, so nothing
regressed for real-world scripts; `01`/`02` still report "already exists", which is
finding #10 rather than a regression.

**Not adopted as the pinned toolchain.** `scripts/setup-tools.sh` still builds from
`main`, because these PRs are unmerged — pinning to a local merge commit would not be
reproducible for anyone else. Worth re-pinning once they land.

---

## What went right

Worth recording alongside the problems:

- `mxcli check --references` caught genuine mistakes early and often — CE0111
  duplicate variables, undeclared return variables, missing entities.
- `create or replace` on microflows and pages makes iteration fast; most of this
  app was rebuilt many times without touching Studio Pro.
- `describe entity` / `describe page` round-trip well and were the fastest way to
  confirm what mxcli had actually written (e.g. finding the `CreatedDate` rename).
- The `.ai-context/skills/` docs are unusually good; every issue above is an
  exception against a large body of accurate guidance.
- The MDL error messages that *do* carry a line and column (parse errors) are
  precise and quick to act on.
