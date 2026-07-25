# mxcli / MDL findings

Issues and limitations hit while building this Sudoku app end to end in MDL —
domain model, a logic solver, a number pad, a dark theme, notes, undo/redo and a
completion page — against **mxcli `2a4494a`** (branch `main`) and **Mendix 11.12.1**.

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

**Limitation.** A `where [...]` constraint cannot compute:

```mdl
retrieve $M from M."Move" where [... and "Seq" = $Game/"MoveSeq" + 1] limit 1;
-- line N:66 mismatched input '+' expecting ']'
```

**Workaround:** compute into a variable first, then compare against it. Fine once
known, but the failure is a parse error rather than a message about XPath.

---

## 9. `mxcli check --references` rejects same-file forward references

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

---

## 16. `mxcli run --hub` registers once and never re-registers

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

**Limitation.** A SCSS error is reported by the watch loop only as:

```
build failed: An error occurred while compiling Theme files
```

with no file or line. Getting the real message (`Expected expression.
_sudoku.scss 180:35`) required running `mxbuild` by hand — which then caused #15.
Surfacing the compiler's own message in the watch output would remove that trap.

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
