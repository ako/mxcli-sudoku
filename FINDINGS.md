# mxcli / MDL findings

Issues and limitations hit while building this Sudoku app end to end in MDL —
domain model, a logic solver, a number pad, a dark theme, notes, undo/redo and a
completion page — against **mxcli `2a4494a`** (branch `main`) and **Mendix 11.12.1**.

**Verification pass (2026-07-25).** Every repro below was re-run against a build
of `main` + open PRs **#26, #27, #28, #29** (merge head `6f976d95`), side by side
with the pinned build, on a scratch copy of the project. Results are recorded per
entry; the summary table is at the end. Two of my original entries turned out to
be **my own misdiagnosis** and are corrected in place — #9 and, partly, #3.

Each entry has the symptom, a minimal repro, and the workaround actually used —
with one exception: **#31 began as a code review of an unmerged PR** rather than
observed behaviour of a shipped build, and says so.
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

> **FIXED, PR #51** (verified live). A failed registration — unreachable hub *or*
> a rejected key — now warns and continues local-only instead of aborting:
> `Warning: hub registration failed (…); continuing local-only — the app runs on
> localhost but has no public preview URL.` See #31 for the test.

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

### Follow-up: the console exporter cannot produce a flame chart

`--trace` defaults to `OTEL_TRACES_EXPORTER=console`, which is right for
"is tracing on?" but prints only name, ids, kind and attributes — **no
start/end timestamps and no parent span id**. Neither a call tree nor a duration
can be reconstructed from it. An OTLP endpoint carries both, and since your own
`OTEL_*` wins, pointing at one needs no new mxcli feature:

```bash
OTEL_TRACES_EXPORTER=otlp OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf \
OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318 mxcli run --local --trace …
```

`scripts/otlp-collect.py` (a dependency-free OTLP/HTTP receiver) and
`scripts/flame.py` in this repo turn that into a flame chart.

**Trace context crosses app boundaries in both directions, out of the box.**
For a multi-app solution this is the question that matters, and it needed no
configuration beyond `--trace` on each app. Tested with two runtimes, the second
started as `mxcli run --local --app-port 8081 --admin-port 8091 --serve-port 6544
--db-name sudokub --trace --trace-service SudokuB`, both exporting to one
collector, with a `rest call` in app A pointed at app B:

```
trace eba84a43…   apps: Sudoku, SudokuB
[Sudoku]  POST /*                              21.19ms  100.0%
  [Sudoku]  Call microflow Sudoku.ACT_Hint     17.98ms   84.8%
    [Sudoku]  Microflow Sudoku.ACT_Hint        13.38ms   63.1%
      [Sudoku]  CallRest activity              12.56ms   59.3%
        [Sudoku]  GET                           8.39ms   39.6%
          [SudokuB]  GET /*                     4.08ms   19.2%   <- the other app
```

- **Outgoing:** a Mendix `rest call` injects W3C `traceparent`. Confirmed
  against a header-echoing server before wiring up the second app:
  `traceparent: 00-b970ddbfc807f620c7c38c381ed0a440-bd672e1ce75254cf-03`, whose
  span id is the `GET` child of the `CallRest` activity.
- **Incoming:** the runtime *extracts* a supplied context rather than starting a
  new trace. `curl -H 'traceparent: 00-abcdef00112233445566778899aabbcc-1234567890abcdef-01'`
  produced `GET /* trace=abcdef00112233445566778899aabbcc parent=1234567890abcdef`
  — the caller's ids, adopted verbatim. (`com.mendix.modules.opentelemetry.MxRuntimeRequestGetter`
  is the class that does it.)

Two things this depends on, worth stating because both are easy to get wrong:
**one collector** — per-app console exporters cannot be correlated at all, since
console output has no timestamps or parent ids (below) — and a **distinct
`OTEL_SERVICE_NAME` per app**, which `--trace` already defaults to the `.mpr`
name, so two apps built from one project need `--trace-service` to tell them
apart. `service.name` rides on the OTLP Resource, not the span, so a collector
that ignores Resource loses which app a span came from; `scripts/otlp-collect.py`
reads it and `flame.py` prefixes each row with `[app]` when a trace crosses more
than one.

**Tracing overhead distorts the profile it is measuring**, and by enough to
mislead. The same deal, traced two ways:

| | total | `ACT_Refresh` share | the `SELECT sudoku` inside it |
|---|---|---|---|
| default span filters | **358 ms** | 10.3% | **4.3 ms** |
| filters off (per-activity) | **3,774 ms** | 57.5% | **2,026 ms** |

Unfiltered, that query looks like the app's dominant cost and is not — it is
~4 ms of work buried under ~19,700 spans of instrumentation. Anyone reading a
flame chart from an unfiltered Mendix trace will chase the wrong thing. Filters
on for timing; filters off only to see the *shape* of a small flow.

---

## 30. The pieces for an "app warehouse" are all there, in four query languages

**Opportunity.** By the end of this build, answering one question about the app
meant four different tools:

| what | where | how you query it |
|---|---|---|
| model metadata | `.mxcli/catalog.db` (SQLite, 70 tables) | `mxcli -c "SELECT … FROM CATALOG.*"` |
| app data | PostgreSQL | `psql`, or `mxcli oql` against the running app |
| traces | OTLP spans | grep a JSONL file, or a trace UI |
| metrics | `/prometheus` | curl and eyeball |
| logs | `.mxcli/runtime.log` | grep |

Each is fine alone. The useful questions cross them, and none of them can.

**Tested: DuckDB reads all of it in place**, no ETL step and no export — the
catalog and the app's PostgreSQL are both `ATTACH`ed read-only, telemetry is
`read_json_auto`. Scope is the **dev container only**: dev data, dev telemetry,
DuckDB as a separate process. Nothing needs to go into mxcli for this to work.

**The catalog is already a database, so query it directly.** `.mxcli/catalog.db`
is SQLite with 70 tables — far more than the `CATALOG.*` views expose in a
single query, and always current. Exporting it to JSON first (which is what I
did initially) is strictly worse: it drags in mxcli's human-readable chatter,
loses 65 of the tables, and goes stale.

**`REFRESH CATALOG FULL` matters.** Plain `REFRESH` leaves `activities_data`,
`refs` and `xpath_expressions_data` **empty** — 0 rows, no error. Full mode
fills them: 718 activities, 472 refs here.

And `activities_data` turns out to answer an earlier open question. Its `Id` is
the **model GUID the debugger takes** (#26) — the one I was extracting by hand
with `mxcli bson dump` and a little-endian GUID walker:

```
SELECT Id, Name, ActivityType, Sequence FROM activities_data
 WHERE MicroflowQualifiedName = 'Sudoku.ACT_Hint' ORDER BY Sequence;

d9bbc0f9-1386-4ad0-b627-78370a595bab   6  RetrieveAction   ActionActivity
```

`d9bbc0f9…` is exactly the GUID I set a breakpoint on. So the catalog gives the
GUID *plus* the action name and its position in the flow — better than the BSON
walk, which only knew `ActionActivity`. `scripts/mfdebug.sh activities` now
reads the catalog and keeps the BSON walk only as a fallback for a
catalog that has not been refreshed in FULL mode.

That also softens the correlation problem from #29: spans still carry no
activity GUID, but the catalog supplies an *ordered, named* activity list per
microflow, so a positional join is grounded in real data rather than guesswork.
`scripts/warehouse.py` builds it; two cross-source joins that were previously
impossible in one query:

*Runtime cost (traces) against model shape (catalog)* —

```
microflow        calls   avg_ms   max_ms  activities  mccabe
ACT_DealGame         2  2393.74  4325.62          76      42
ACT_Refresh          3   742.56  2054.66          45      23
ACT_Set1             1   148.91   148.91           2       1
ACT_MarkPeers        6    29.09    52.59          14       7
```

Complexity does not predict cost: `ACT_Set1` is two activities and McCabe 1, and
costs five times `ACT_MarkPeers` at fourteen activities — because it delegates.
A lint rule flagging complexity cannot see that; this join can.

*Query time (traces) x entity (catalog) x live rows (the app's own Postgres)* —

```
entity      tbl                  op       queries  total_ms
(system)    system$queuedtask    SELECT      1103   4083.58
Game        sudoku$game          INSERT         2    418.01
Cell        sudoku$cell          INSERT         2    373.10
Cell        sudoku$cell          SELECT        15     53.72
```

The task-queue poller is the single largest database consumer in this app by an
order of magnitude, and it belongs to no microflow — invisible from any
per-microflow view. Knowing `system$*` is not yours requires the catalog;
knowing it costs 4s requires the traces.

**The context argument holds, and is the strongest part.** The raw sources
behind those two tables:

```
traces        2528.5 KB   ~647,000 tokens
logs           108.3 KB    ~27,700
metrics         20.4 KB     ~5,200
catalog         19.5 KB     ~5,000
                        ~685,000 tokens total
```

Both answers together are **under 3 KB**. That is the difference between a
question being answerable and not.

**One real gap: logs cannot be joined to traces.** Runtime log lines carry no
trace id — `grep -cE '[0-9a-f]{32}'` over the whole log returns 0 — so
logs↔traces is a timestamp join, which is fuzzy exactly when it matters (under
concurrency). The agent *ships* the log-correlation instrumentation (97
log4j/logback classes in the javaagent jar), so the trace id is available in MDC;
Mendix's log pattern just does not print it. Adding `%X{trace_id}` to the runtime
log format would close it — a one-line change with more leverage than anything
on the mxcli side.

**Caveats worth stating.** DuckDB adds a CGO-free but non-trivial dependency if
this were to live inside mxcli; span volume is the real storage question (one
unfiltered deal is ~110k spans / 10 MB); and attaching the app's production
database read-only is a decision that deserves an explicit flag, not a default.

---

## 31. Hub authentication (PRs #50, #51) — all findings fixed, verified live

> **RESOLVED.** PR #50 fixed the four code-level concerns before merging; **PR #51
> then fixed every remaining item** — the shared-secret regression, the fatal
> abort, the unusable device flow, and key durability — citing this finding by
> name (`hub-auth: post-deploy fixes from sudoku finding #31`). Each was
> re-tested against the updated live hub; the results table is at the end of this
> entry. What follows is the original report, kept so the reasoning is auditable.
>
> **All four code-level concerns below were fixed before PR #50 merged**
> (`e06015ed`), each with a test. Verified against the merged build: a session
> cookie and an OAuth state are no longer interchangeable (checked both
> directions), and — now confirmed **against the live hub**, not just a unit
> test — an anonymous `GET /api/backends` returns `401 authentication required`
> where it previously returned every user's previews. The remaining items are
> operational and are corrected below.

**Note on status.** Unlike every other entry here, this began as a **code review
of an unmerged PR** rather than observed behaviour of a shipped build.
`hub.mxcli.org` had not been updated, so nothing was exercised against a live
hub; the claims that are proven were proven with throwaway unit tests against the
branch.

PR #50 adds GitHub OAuth to `mxcli tunnel-hub`: a `Backend.Owner`, an
HMAC session cookie for viewers, hub API keys minted per user, and an OAuth
device flow in `mxcli auth hub login`. The design is sound — owner is derived
server-side (`req.Owner = owner // never trusted from the body`, with `json:"-"`
keeping it off the wire), keys are stored SHA-256-hashed and returned in plain
exactly once, `Owner` leads `identity()` so two users cannot collide on a slot,
`safeReturn` closes the OAuth open-redirect, and `audit.Event` has **no field**
for a token or cookie, so a secret cannot be logged by accident. Open mode is
preserved throughout.

### The leak: `/api/backends` returns everything to an anonymous caller

`sessionLogin()` returns `""` for two different situations — **auth is off** and
**the cookie is missing or invalid** — and `List(sort, "")` means "return
everything". `/api/backends` has no gate of its own. So on a hub started with
`--require-auth`, an unauthenticated GET lists every user's previews. Proven
against the PR branch:

```
HTTP 200, 2 backend(s) returned to an anonymous caller
   owner="alice" project="AppA" subdomain="appa"
   owner="bob"   project="AppB" subdomain="appb"
```

That exposes subdomain, project, branch, owner login and ports — enough to
enumerate every live preview and try each one. The owner check on the preview
path itself is correct; it is the listing that is open.

**Fixed as merged:** `handleBackends` now branches on `Auth.enabled()` and
answers 401 when auth is on and no valid session is present, with
`TestAPI_BackendsRequiresAuthWhenEnabled` covering the HTTP path. The original
suggestion, for the record:

**Fix:** stop overloading `""`. Resolve the viewer as
`(login string, authRequired bool)` and have `handleBackends` answer 401 (or an
empty list) when auth is enabled and no valid session is present, instead of
falling through to unfiltered. Registry-level filtering *is* tested
(`List("project", "alice")`); the missing test is the HTTP path with auth on and
no cookie. The admin HTML page deserves the same check — only the API was proven.

### Operational: a stale key kills the whole run, not just the preview

> **Corrected after review feedback.** I first filed this as "the in-memory key
> store must be persisted". That was the wrong end of it: on a dev hub, where the
> hub and the apps both restart often, re-running `mxcli auth hub login` is a
> ~30-second interruption and entirely reasonable. Persistence is not the fix.

What actually bites is the *coupling* to #27. `KeyStore` is a map that dies with
the process, so every hub restart invalidates `MXCLI_HUB_KEY` — and a rejected
key is fatal to the whole local run:

```go
hubReg, err = RegisterWithHub(opts.Hub, opts.HubSecret, opts.HubKey, meta, opts.AppPort)
if err != nil {
    return fmt.Errorf("hub registration: %w", err)   // no local app either
}
```

So the developer does not get "no preview until I log in again" — they get **no
app at all**, with an error pointing at the hub rather than at
`mxcli auth hub login`. That is #27 reached by a second route: an unreachable hub
and a stale key both take the local run down with them.

Two supporting details, minor on their own:

- In a headless container the device flow **cannot be run at all** — see the next
  section. This only matters because of the fatal abort above.
- The hub's `POST /api/keys` accepts a plain GitHub token as
  `Authorization: Bearer`, but `mxcli auth hub login` is device-flow only — there
  is no `--token` flag. Adding one would make automation self-serving from a PAT
  with no persistence work at all.

**Fix #27 and this evaporates.** Make a failed registration cost the preview URL
and nothing else; then keys dying on restart is the minor annoyance it should be,
and persisting them becomes optional rather than a prerequisite for turning
`--require-auth` on.

### `auth hub login` cannot run in a Claude Code web container at all

Tested against the live authenticated hub (`authEnabled: true`,
`requireAuth: true`). `mxcli auth hub login` fails before it prints a code:

```
Error: device-code request returned HTTP 403
```

That 403 is **not from GitHub** — it is this container's egress gateway:

```
POST https://github.com/login/device/code
{"message":"This GitHub API path is not available: sessions are bound to their
 configured repositories. Use repository-scoped endpoints (repos/{owner}/{repo}/...)."}
```

A Claude Code web session may only reach *repository-scoped* GitHub API paths, so
`login/device/code` and `login/oauth/access_token` are both barred. This is
structural, not a missing human: no amount of authorizing in a browser helps,
because the container cannot start the flow. `api.github.com` answers 200 through
the same proxy, which is what makes the failure look like a GitHub problem at
first glance.

Consequences, in order of how much they hurt:

1. **`MXCLI_HUB_KEY` is not a convenience for these containers — it is the only
   route.** The key has to be minted somewhere with unrestricted GitHub egress
   (a laptop, or `curl -H "Authorization: Bearer <PAT>" -X POST
   https://hub.mxcli.org/api/keys`) and then set as an environment secret.
2. **The error message advises something impossible here.** The 401 says
   `run 'mxcli auth hub login'`, which in this environment can never succeed. It
   would help to name `MXCLI_HUB_KEY` as the alternative.
3. **A `--token` flag on `auth hub login` would fix it properly.** The hub already
   accepts a GitHub token as `Authorization: Bearer` at `POST /api/keys`; only the
   CLI insists on the device flow. `mxcli auth hub login --token $GH_TOKEN` would
   let a restricted container mint its own key from a PAT.

### Live confirmation of the fatal abort

With no key, against a `--require-auth` hub:

```
Registering with hub https://hub.mxcli.org...
Error: hub registration: hub registration failed (HTTP 401):
       missing or invalid X-Hub-Key (run 'mxcli auth hub login')

local app afterwards: HTTP 000   <- nothing running
```

The 401 itself is well worded. But the run is over: no local app, no warm loop,
no `--watch`. Combined with the section above, a Claude Code web container
pointed at an authenticated hub without a pre-set `MXCLI_HUB_KEY` gets **no app
at all**, and is told to run a command it cannot run. That is #27's fix — degrade
to local-only — doing double duty.

### The shared secret stops working the moment auth is enabled

Tested against the live hub: the legacy `X-Hub-Secret` is rejected outright.

```
POST /api/register  -H 'X-Hub-Secret: alice:s3cret'
  HTTP 401 — missing or invalid X-Hub-Key (run 'mxcli auth hub login')
```

Not "overridden by a key" — **never consulted**. `authorizeRegister` reads the
secret only inside `if !a.opts.Auth.enabled()`, so enabling GitHub auth makes that
branch unreachable:

```go
if !a.opts.Auth.enabled() {
    ... X-Hub-Secret gate ...        // open mode only
    return "", true
}
key := r.Header.Get("X-Hub-Key")     // auth on: key or nothing
```

The client dutifully sends both headers ("Both are sent when present so the hub
picks the one matching its own mode") — but the hub never looks at the secret.

**The awkward part is the middle setting.** With auth enabled there are only two
states, and neither is "secret still gates registration":

| | registration | listing |
|---|---|---|
| open mode (no client id) | shared secret | everything |
| auth + `--require-auth` | valid `X-Hub-Key` only | 401 without a session |
| auth + soft mode | **ungated — no key *and* no secret** | 401 without a session |

Soft mode reaches `return "", true` without checking anything, so it is not a
gentler gate — it is *open registration*, on a hub whose operator has just turned
authentication on. Anyone who can reach `/api/register` can claim a subdomain;
previews are merely owner-less. That is very likely not what "soft mode" sounds
like from the flag name.

**Suggestion:** honour `RegisterSecret` as a fallback when auth is enabled — a key
stamps an owner, a valid secret registers owner-less, and no credential is
refused. That keeps existing `--hub-secret` setups working through the migration
and makes soft mode an actual gate rather than an open door.

### FIXED by PR #51 — re-tested against the live hub

Every remaining item closed. Verified against `hub.mxcli.org` after it was
updated, not from the diff:

| check | before | after |
|---|---|---|
| register with the shared secret | 401 | **200**, owner-less |
| register with a key only | — | **200**, owner stamped |
| key ⇒ owner ⇒ preview gated | — | **302 → GitHub login** |
| secret ⇒ owner-less ⇒ preview open | — | no redirect, proxies through |
| anonymous `/api/backends` | 200 + every preview | **401** (still) |
| unauthenticated key mint | — | **401** |
| `/cli` browser key page | did not exist | **302 → GitHub login** |
| `auth hub status` reads `MXCLI_HUB_KEY` | — | `Source: env (MXCLI_HUB_KEY)` |
| rejected key | **whole run aborted** | **app up local-only**, warning |

The degradation is the #27 fix doing its job. With a deliberately bogus key:

```
Warning: hub registration failed (HTTP 401): missing or invalid X-Hub-Key …
         continuing local-only — the app runs on localhost but has no public preview URL.
```

`authorizeRegister` now takes the shape suggested above — a key stamps an owner,
a valid secret registers owner-less, and soft mode gates when a secret is
configured instead of being open registration. The device flow is deleted in
favour of browser issuance at `/cli` plus `--token` for headless use, which is
what makes this usable from a container that cannot reach GitHub's OAuth
endpoints. The key store is now file-backed, so keys survive a hub restart.

**Two things I got wrong while testing, recorded because the corrections matter
more than the findings did:**

1. I reported a contradiction — our preview redirecting to login while a
   secret-registered probe did not — and started hunting a bug. The cause was
   that `MXCLI_HUB_KEY` had been set in the environment between my two checks, so
   our app registered *with a key* and was correctly owner-gated. Both behaviours
   were right. Check the process environment before calling behaviour inconsistent.
2. A **302 on a preview is the feature, not a failure**: `curl` carries no
   session, so the owner check bounces it to GitHub. Only a browser signed in as
   the owner can confirm the other half, which is the one thing not verified here.

**Not verified:** viewing a gated preview *as the owner* (needs a browser
session); key durability across a hub restart (the key survived a deploy, but I
cannot tell whether it predates the restart, so the claim is unproven);
`auth hub login --token` (needs a PAT, and this container is barred from GitHub's
OAuth endpoints regardless).

**Still open, cosmetic:** `mxcli auth hub login --help` still reads "Mint and
store a hub API key via GitHub device flow" although `deviceflow.go` is deleted.

### Smaller

All four were fixed before merge; kept here for the record.

- ~~`exchangeCode` and `fetchLogin` ignore `resp.StatusCode`~~ — both now check it
  and return a real error. Originally: Not
  exploitable — an empty token yields an empty login, which *is* checked — but a
  GitHub error body decodes "successfully" into a zero value, so the failure
  surfaces as the wrong message.
- ~~`signState` reuses the session HMAC~~ — now `signTagged(secret, tag, …)` mixes
  a domain tag into the MAC (`tag ‖ 0x00 ‖ payload`) and each verifier accepts
  only its own tag, so the two token types are no longer interchangeable.
- ~~`clientIP` trusts `X-Forwarded-For`~~ — now deliberately does **not**, with the
  reasoning recorded: the hub terminates TLS itself, so `RemoteAddr` is the real
  peer and XFF is attacker-controlled. A fronted deployment would need an
  explicit allow-listed-proxy option first. A better answer than the one I gave.

- **Still open:** `POST /api/keys` has no rate limit and keys never expire, so one
  valid GitHub token can mint unbounded map entries; there is still no way to list
  or rotate keys, only to revoke the one you hold.

## 32. Upgrading a widget package on MPR v2 costs you the v2 layout

> **Partly addressed in `4fda072f` by `mxcli widget sync` — see finding 38**,
> which reaches instances mxcli did not author and preserves `mprcontents/`,
> but currently writes duplicate GUIDs that leave the project unsavable.
>
> Finding 37 records the gap underneath this one — that an installed marketplace
> module cannot be updated at all. This entry is about what happens on MPR v2
> once you update the payload by hand anyway.

Build under test: `main` `09f24ce8`. Mendix 11.12.1, project on MPR v2 (409
`mprcontents/*.mxunit`). Attempted upgrade: Data Widgets **3.5.0 → 3.11.3**
(marketplace id 116540), which moves all nine widgets from 3.3.0/3.4.0 to 3.11.3.

Neither available tool performs the update, each for a stated reason:

```
$ mxcli marketplace install 116540 -p Sudoku.mpr
Module "DataWidgets" is already installed (version 3.5.0).
Target version: 3.11.3.
In-place module updates are not applied automatically (they can discard local
edits and change persistent-entity IDs, which loses data). Update via Studio Pro.

$ mx module-import DataWidgets-3.11.3.mpk Sudoku.mpr
error 3: Project already contains a module with the name of an importing module.
```

The guard mxcli cites does not apply to this module: `DataWidgets` holds **0
entities** — its entire model contribution is the `Filter_Operators`
enumeration, which is **identical in 3.5.0 and 3.11.3** (same name, same folder,
12 values, compared by opening the package's own `project.mpr`). The JS action
file set is identical, and `themesource/` only *adds* `_pagination-bar.scss`
(which `main.scss` already `@import`s). So for this package the payload — nine
`.mpk`s, `themesource/datawidgets`, `javascriptsource/datawidgets` — *is* the
upgrade, and copying it in is safe.

Doing that leaves the model stale, exactly as expected:

```
mx check  ->  31 errors, all CE0463 "The definition of this widget has changed"
```

Per mxcli's own `diagnose-ce0463` skill this is **Case A** (package upgraded
after the widgets were authored) — not an mxcli bug, and what "Update all
widgets" exists for. The problem is what it costs on MPR v2:

| path | CE0463 | `mprcontents/` |
|---|---|---|
| payload swapped, nothing else | 31 | 409 units |
| `mx update-widgets` | **0** | **0 units — collapsed to v1** |
| `mxcli exec` re-authoring our pages | 29 | 409 units |

`mx update-widgets` fixes everything and destroys the v2 layout (the skill warns
about this; confirmed here). mxcli's own reconciliation preserves the layout but
**only reaches instances it authors**: it cleared both of our galleries
(`galBoard`, `galRecent`) and nothing else. The 29 that remain are Studio Pro's
own template widgets in Administration / Atlas_Web_Content / FeedbackModule —
`gallery1` ×7, `gallery2` ×4, `dataGrid2_*` ×11, `drop_downFilter1/2` ×7 — pages
no MDL in this project touches. They were clean at 3.4.0, so the upgrade is what
broke them.

The collapse is **one-way with the tools in the container**. `mxcli exec` against
a collapsed project does not rebuild `mprcontents/` (tested: 0 units before, 0
after). `modelsdk/mpr/reader.go:149` points at a recovery command —

> `restore mprcontents/ before opening for writing, or use mxcli mpr-pack to-v1
> to convert to a self-contained file`

— but `mpr-pack` is **not implemented**: `unknown command "mpr-pack" for
"mxcli"`. That message names a command that does not exist, and in any case
offers only v1, not the v2 direction that would help.

**Net effect.** On MPR v2 you can have the widget upgrade or the reviewable
multi-file layout, not both, unless you own Studio Pro. For a repo whose whole
premise is that the model is authored and reviewed as text, that is a real cost:
409 files become one binary blob. This is the gap
`docs/…/PROPOSAL_widget_instance_reconciliation.md` appears aimed at, and this is
a concrete case for it — the missing piece is reconciling instances mxcli did not
author, generically, in place.

**Left at 3.4.0** in this repo pending that, since nothing here needs 3.11.3.

## 33. `Client: Script error.` on every interaction — server clean, cause unreachable

Four games across two mxcli builds (`0580eadf`, `689e8ce4`) and two versions of
the microflow. Every game produces one client-side error per interaction:

```
68 errors / 68 ACT_MarkPeers      73 / 72      81 / 118*      (*overlapped a benchmark;
                                                               1:1 once isolated)
```

The relationship is exact and it is with `ACT_MarkPeers`, which runs at the end
of both `ACT_SelectCell` and `ACT_Refresh` — hence "whatever I do, a pop-up".
The interleaving is always the same:

```
03:14:12.836 ERROR - Client: Script error.
03:14:12.859 INFO  - Sudoku: ACT_SelectCell row=8 col=7
03:14:12.872 INFO  - Sudoku: ACT_MarkPeers
```

**The server side is clean.** Zero server errors in any session; every microflow
completes and moves are saved. This is a browser-side exception on top of working
logic.

What has been ruled out: the app has no external scripts (only a Google Fonts
`@import`); the play page has no custom JS (the only client logic is
`NF_ToggleNotes`); it is not a stale tab or a restart artifact (it starts while
the app is healthy); and it is not the cross-origin stylesheet (stubbing the
fonts sheet in so it *loads*, then driving 13 `ACT_MarkPeers` cycles, produced
zero errors).

It has never reproduced from the container — 51 selections and 32 digit entries
across driven sessions, no script error — only from a real browser against the
hub URL.

**Why it is stuck.** `Script error.` with no file or line is the browser
withholding detail for a cross-origin exception, so the server learns nothing.
Raising the `Client` log node to TRACE changes nothing (`set_log_level` returns
`result: 0` and the message stays bare). And the hub now gates previews behind
GitHub OAuth, whose endpoints the sandbox egress blocks, so a headless browser
here cannot load the page at all. The exception exists only in a real player's
DevTools console, which is the one place this agent cannot reach.

Worth noting as an observability gap in its own right: **a client-side error that
breaks the app for every user is, server-side, indistinguishable from noise.**

## 34. The container suspends when the session idles, taking the app with it

Not an mxcli bug, but it dominates how mxcli is used from Claude Code on the web,
and it was misdiagnosed twice before being pinned down.

The container is reclaimed when the agent session goes idle. Every process dies:
the app, the tunnel, PostgreSQL, and the OTLP collector. Measured window ≈ 8
minutes from the end of a turn. Observed timeline: app launched 03:08, turn ended
≈ 03:12, player active 03:13–03:16, container reclaimed ≈ 03:20, `SessionStart`
hook relaunched onto a *new* runtime. From the player's side the preview simply
stops; from the agent's side the traces for the period of interest are gone.

Consequences worth stating plainly:

- **A hub preview is only reachable while the agent session is active.** Nothing
  in a launch script can change this; the whole container freezes.
- Recovery therefore runs constantly, which makes the recovery path the hot path.
- A first diagnosis of "your tab is stale after a restart" was **wrong** — the
  errors in finding 33 began while the app was healthy, eight minutes before any
  restart. Timestamps settled it; the restart was a second, unrelated event.

Two hook bugs this exposed in *this* repo (both now fixed here, `a604f83`):

1. Two entries in one `SessionStart` `hooks` array run **concurrently, not
   sequentially**. `run-app.sh` raced `setup-tools.sh` and repeatedly launched
   the app on an mxcli binary being replaced underneath it — the process holds a
   deleted inode and silently serves the previous build. Nothing in any log says
   so; only `readlink /proc/<pid>/exe` reveals it (`... (deleted)`). Chain the
   commands with `&&`.
2. A relaunch that omits `--metrics`/`--trace-otlp` silently loses all
   observability for the rest of the session, and the runtime discards spans
   when nothing is listening on 4318 — so the collector must start *first*.

## 35. What tracing is good for, and how it misled me

Spans across four played games, `--metrics --trace-otlp`. The app is healthy:
`ACT_SelectCell` p50 ≈ 29 ms, a digit entry ≈ 35–70 ms, game start 1.05 s warm
(4.8 s cold — the cold/warm split is large enough to invalidate any measurement
taken on a fresh boot).

**A correction, recorded because the failure mode is general.** From the span
list I reported that the 81-cell list was "retrieved twice per interaction,
1.79 s over a game, the app's single largest cost". That was wrong. Attributing
each `Retrieve //Sudoku.Cell[Sudoku.Cell_Game = $Game]` span to its *parent*
shows the parent is `POST /*` — these are the **client's** board refetch after
each interaction, and were never inside `ACT_MarkPeers` at all. Grouping spans by
name reads like a profile and is not one; only the parent chain tells you who
paid. The real duplicate was one `SELECT` per call.

Fixing that (pass the list into `ACT_MarkPeers` instead of re-retrieving it,
commit `5895a3c`) measured, on a real game before and after:

```
ACT_MarkPeers    p50 8.55ms / 3 queries -> 3.62ms / 2 queries
ACT_Refresh      p50 15.41 / 5          -> 11.29 / 4
ACT_ApplyValue   p50 27.28 / 11         -> 22.53 / 10      (a move)
ACT_SelectCell   p50 18.98 / 8          -> 17.04 / 8       (flat, as predicted)
ACT_LogMove      p50 8.07               -> 7.61            (untouched — control)
```

Real, and about a hundredth of what was projected. `ACT_LogMove` holding still is
what makes the rest credible.

Also visible, and not app code: the Mendix **queued-task poller issues 47–64% of
all database queries** (e.g. 3843 of 5979 in one session, ≈ 2.7–3.4 q/s) with
nothing queued. It is harmless on a dev box but it dominates any query profile
taken there, so it has to be filtered out before the app's own numbers mean
anything.

## 36. `get_log_settings` throws instead of answering

Minor, but it costs a debugging step. `set_log_level` works:

```
$ curl -d '{"action":"set_log_level","params":{"nodes":[{"name":"Client","level":"TRACE"}]}}' :8090
{"feedback":{},"result":0}
```

Reading them back does not:

```
$ curl -d '{"action":"get_log_settings"}' :8090
{"result":1,"message":"class com.mendix.m2ee.api.internal.AdminException occurred
 while executing an admin action request."}
```

with `ERROR - M2EE: Please specify node, subscriber or sort option in params` in
the runtime log. The action evidently requires parameters that neither the error
nor any documentation names, so there is no way to confirm a log level actually
took effect — which matters when a level change is the experiment (finding 33).

## 37. There is no way to update an installed marketplace module

Finding 32 is the *consequence* of this one on an MPR v2 project. The gap
underneath it is simpler and broader: **mxcli can install a marketplace module
but cannot update one**, and nothing else in the container can either.

Keeping marketplace modules current is routine maintenance, not an edge case. In
this app, six of seven are behind — most by several minor versions:

| module | installed | latest |
|---|---|---|
| Administration | 4.3.2 | 4.5.0 |
| Atlas_Core | 4.1.3 | 4.3.7 |
| Atlas_Web_Content | 4.1.0 | 4.3.0 |
| DataWidgets | 3.5.0 | 3.11.3 |
| NanoflowCommons | 6.0.0 | 7.2.1 |
| WebActions | 2.11.0 | 2.11.2 |
| FeedbackModule | 4.0.2 | — |

`mxcli marketplace` covers discovery well — `search`, `info`, `versions`,
`download` all work against a `MENDIX_PAT`, and `install` is genuinely useful for
a module the project does not yet have. The moment the module is already present,
every route closes:

```
$ mxcli marketplace install 116540 -p Sudoku.mpr
Module "DataWidgets" is already installed (version 3.5.0). Target version: 3.11.3.
In-place module updates are not applied automatically … Update via Studio Pro.

$ mx module-import DataWidgets-3.11.3.mpk Sudoku.mpr
error 3: Project already contains a module with the name of an importing module.
```

mxcli's caution is reasonable in general — an in-place update can discard local
edits, and for a module with persistent entities it can change entity IDs and
lose data. But it is unconditional, so it also blocks the cases where it is
provably safe. `DataWidgets` has **0 entities**; its whole model contribution is
one enumeration that is byte-identical between the installed and target versions.
There is no way to tell mxcli that, and no `--force` to take responsibility for
it.

**The recorded version cannot even be corrected.** Having swapped the payload by
hand (finding 32), the model still says 3.5.0, and the two tools disagree about
what that field even is:

```
$ mxcli show modules            ->  DataWidgets   Marketplace v3.5.0
$ mx show-module-version Sudoku.mpr DataWidgets
Module 'DataWidgets' does not have a version.
$ mx set-module-version Sudoku.mpr DataWidgets 3.11.3
Module 'DataWidgets' does not have a version.        # no-op
```

So a hand-updated module is indistinguishable from a stale one, which makes the
manual route unsafe to repeat: nothing records that it happened.

**And the manual route only exists for widget-shaped modules at all.** Swapping
`widgets/`, `themesource/` and `javascriptsource/` works for `DataWidgets`
because those files *are* the module. For `Administration` (2 entities, 9 pages,
8 microflows) or `NanoflowCommons` (2 entities, 3 enums) the model content *is*
the module, and there is no file-level equivalent — the update has to be a model
merge. Those are exactly the modules where the entity-ID risk mxcli cites is
real, and exactly the ones with no path forward.

### What would close it

In rough order of value:

1. **`mxcli marketplace update <id>`** that diffs the packaged module's model
   against the installed one and reports what would change — added/removed
   entities and attributes, changed microflows — before touching anything.
   Read-only, it would already be useful: today there is no way to know what an
   update contains without importing it into a scratch project.
2. **An escape hatch for the safe cases** — a module with no persistent entities
   and no local edits is a file replacement plus a version bump. `--force`, or a
   check that proves the model contribution is unchanged.
3. **A writable version field**, so a hand-updated module can be recorded as
   such.

### Why this matters more here than it looks

The premise of this project is a Mendix app authored end to end through
mxcli/MDL, never opening Studio Pro. That holds for everything we write. It stops
holding for everything we *depend on*: the moment a marketplace module needs
updating — for a fix, a security patch, or a runtime upgrade — the workflow
requires the one tool it set out to avoid. An app that can be built but not
maintained through the CLI is only half-automatable, and this is the boundary.

## 38. `mxcli widget sync` — the right idea, and it currently corrupts the project

Build under test: `main` `4fda072f` (PR #89, `claude/widget-sync-inventory`). This
is the direct answer to finding 32: `mdl/executor/widget_sync.go` says so in its
own header —

> Studio Pro has "Update all widgets"; mxbuild has `mx update-widgets`, which on
> MPR v2 destroys `mprcontents/`. This is the mxcli equivalent that does not.

The command is also honest about being incomplete: `--help` says "PARTIAL … On
the reference fixture it clears 7 of 40 CE0463 errors", and recommends `--dry-run`
plus `mx check` before relying on it. Both are accurate.

### What it gets right

Re-run of the Data Widgets 3.5.0 → 3.11.3 upgrade from finding 32, same project,
same payload:

| path | CE0463 | `mprcontents/` |
|---|---|---|
| payload swapped, nothing else | 31 | 409 |
| `mx update-widgets` | 0 | **0 — collapsed to v1** |
| `mxcli exec` re-authoring our pages (build `09f24ce8`) | 29 | 409 |
| **`mxcli widget sync`** | **24** | **409 preserved** |

The important part is not the count but the reach: `--dry-run` planned 622
property changes across 58 instances in 27 containers, and the plan covers
widgets **mxcli never authored** — `dataGrid21` on `Administration.Account_Overview`,
`gallery1` on Atlas page templates — which is exactly what finding 32 said was
missing. The 7 it clears are the drop-down filters (`drop_downFilter1` ×4,
`drop_downFilter2` ×3), consistent with PR #85's focus.

The plan output is good: per container, per widget, each property with the
declaring package and version (`+ autoSelect  declared by Gallery 3.11.3, default
"false"`), split across 574 additions, 18 drops, 30 redefinitions.

It is also idempotent — a second pass reports "Every stored widget instance
already matches its installed package. Nothing to do." **while `mx check` still
reports 24 CE0463.** So the residual cause is something other than property
schema, and sync currently has no way to see it.

### The bug: it writes duplicate GUIDs, and that is a one-way door

Applying requires `MXCLI_ENGINE=legacy` (documented in `--help`; `--dry-run`
works on both engines). The result loads and validates — `mx check` reports its
24 errors happily — but it **cannot be saved** by Mendix tooling:

```
$ mx update-widgets t5/Sudoku/Sudoku.mpr
ERROR: System.InvalidOperationException: An error occurred while saving the project:
Duplicate Guid in unit page template 'Atlas_Web_Content.Detail_Timeline'.
  Object types: …CustomWidgets.WidgetProperty, …CustomWidgets.WidgetProperty
                …CustomWidgets.WidgetValue,    …CustomWidgets.WidgetValue
                …Forms.Actions.DoNothingClientAction, …DoNothingClientAction
```

Worse, `mx update-widgets` collapses `mprcontents/` *before* it fails to save. So
the project is left both flattened **and** unloadable:

```
$ mx check t4/Sudoku/Sudoku.mpr
ERROR: Mendix.Modeler.Storage.StorageFormatException: Root unit not found.
```

Reproduced twice, on independently built copies (`t4`, `t5`). The control
isolates it to sync: the **same payload without sync**, then `mx update-widgets`,
saves fine and yields 0 errors (finding 32's table, row 2). The differentiator is
`mxcli widget sync`.

Note the duplication is *not* uniform — `Sudoku.Game_Play`, which sync also
touched, is clean afterwards (900 → 978 objects, 978 distinct GUIDs, 0
duplicated). It shows up on Atlas page templates, so it is likely tied to a
container shape mxcli's authoring path does not otherwise produce.

**Consequence.** In its current state `widget sync` is a trap: it looks like it
worked (the project loads, errors drop, the layout survives), but it silently
forfeits the only complete fix. After running it you can no longer fall back to
`mx update-widgets`, and a Studio Pro save would presumably hit the same
duplicate-GUID rejection. Since sync clears 7 of 31 and `update-widgets` clears
31 of 31, running sync trades the complete fix for a partial one — irreversibly,
and with nothing warning you.

**Recommended, in order:** (1) fix the duplicate-GUID generation — it makes every
other property of this command moot; (2) until then, have `widget sync` refuse or
loudly warn that it is a one-way door; (3) then chase the residual 24, which the
idempotency result shows are not a property-schema problem at all.

**Not applied to this repo.** Left at Data Widgets 3.4.0, as in finding 32.

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
| 27 | unreachable hub aborts the whole run | **Fixed** (#51) — degrades to local-only |
| 28 | nanoflow log node rewritten; paused nanoflows only in `poll_events` | **New** |
| 29 | OTel metrics/traces unreachable from `run --local`; per-activity spans unusable | **Fixed** (#46) — `--metrics` / `--trace` / `--runtime-setting` |
| 30 | model, data, traces, metrics and logs need four query languages | **New** — DuckDB joins them; logs lack a trace id |
| 31 | hub auth: anonymous `/api/backends` listed every preview; secret retired; run aborted on a bad key | **All fixed** (#50 + #51), each re-tested against the live hub |

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
