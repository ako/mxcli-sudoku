# MDL Syntax Validation Skill

This skill ensures MDL scripts are validated before presenting them to users or executing them.

## When to Use This Skill

**ALWAYS** use this skill before:
- Presenting MDL code to users
- Executing MDL scripts via `mxcli exec`
- Committing MDL files to version control

## Pre-Flight Validation Checklist

Before writing any MDL, verify these requirements:

### 1. Check Supported Syntax

**Supported in Microflows:**
- `declare $Var type = value;` (primitives only: String/Integer/Long/Decimal/Boolean/DateTime/Enumeration)
- `$entity = create Module.Entity (...);` / `retrieve $entity from ... limit 1;` (objects — **never** `declare` an object; that fails CE0053/CE0038 and is flagged MDL043)
- `$list = create list of Module.Entity;` (lists — **never** `declare` a list; that fails CE0053/CE0038 and is flagged MDL040)
- `set $Var = expression;`
- `$Var = create Module.Entity (attr = value);`
- `change $entity (attr = value);`
- `commit $entity [with events] [refresh];`
- `delete $entity;`
- `retrieve $Var from Module.Entity [where condition];`
- `$Result = call microflow Module.Name (Param = $value);` (NOT `set $Result = ...`)
- `$Result = call nanoflow Module.Name (Param = $value);`
- `show page Module.PageName ($Param = $value);`
- `close page;`
- `validation feedback $entity/attribute message 'message';`
- `log info|warning|error [node 'name'] 'message';`
- `if condition then ... [else ...] end if;`
- `loop $item in $list begin ... end loop;`
- `return $value;`
- `on error continue|rollback|{ handler };`

**Now Supported (previously not):**
- `rollback $entity [refresh];` - Reverts uncommitted changes
- `retrieve ... limit n` - Returns single entity when `limit 1`
- `boolean` without `default` - Auto-defaults to `false`
- `buttonstyle: warning` and `buttonstyle: info` - Now parse correctly
- Keywords as attribute names - `caption`, `label`, `title`, `text`, `content`, `format`, `range`, `source`, `check`, etc. all work unquoted

**NOT Supported (will cause errors):**
- `set $var = call microflow ...` - Use `$var = call microflow ...` (no SET)
- `while ... end while` - Use `loop` with lists
- `case ... when ... end case` - Use nested `if`
- `TRY ... CATCH` - Use `on error` blocks
- `break` / `continue` - Not implemented
- `commit message 'text'` - Not in current grammar (session command only)

### 2. Quote All Identifiers

**Best practice: Always quote all identifiers** (entity names, attribute names, parameter names) with double quotes. This escapes every **MDL parser** keyword conflict — quotes are stripped automatically by the parser.

> **Caveat — quoting does not exempt *platform*-reserved member names.** Quoting
> only escapes MDL *parser* keywords. Names the Mendix *platform* reserves for entity
> members are still rejected after the quotes are stripped: `Type` (CE7247, MDL021),
> the system audit attributes `CreatedDate` / `ChangedDate` / `Owner` / `ChangedBy`
> (MDL020 — use the `AutoCreatedDate` / `AutoChangedDate` / `AutoOwner` / `AutoChangedBy`
> pseudo-types instead), plus the CE7247 word list (`ID`, `GUID`, `CurrentUser`, Java
> keywords, …). `"Type": String` still fails MDL021 — rename to a non-reserved name
> (e.g. `ResourceType`, `TypeValue`). "Always safe to quote" covers parser keywords, not
> these.
>
> **Exception — never quote `$`-prefixed variable/parameter references.** The quote
> rule is for *bare* names (entities, attributes, associations, declared parameter
> names). Variable and parameter **references** in expressions and widget bindings
> stay **unquoted**: `datasource: $X`, `params: { $X: MES."Order" }`, `$currentObject`.
> Quoting them (`"$X"`) breaks resolution ("parameter … references '$X' but no such
> parameter is declared").
>
> **Enumeration values: no `=`.** Value names may be quoted like any identifier, but
> the caption follows as a quoted string — there is **no equals sign**:
> `create enumeration Mod.E ("Grade1" 'Grade 1', Grade2 'Grade 2');` (or `Grade1 caption 'Grade 1'`).
> Writing `"Grade1" = 'Grade 1'` fails with `mismatched input '='` — the `=` is the
> problem, not the quotes.

```sql
create persistent entity Module."Customer" (
  "Name": string(200),
  "status": string(50),
  "create": datetime
);
```

Both `"Name"` and `` `Name` `` syntax are supported. Prefer double quotes for consistency.

Run `mxcli syntax keywords` for the full list of 320+ reserved keywords.

### 3. Validate with mxcli

**Always run these checks:**

```bash
# Step 1: Syntax check (no project needed)
./bin/mxcli check script.mdl

# Step 2: reference validation (needs project)
# Validates microflow bodies, entity/enum references, and widget tree references
# (datasource microflow/nanoflow/entity, action page/microflow, snippet refs)
./bin/mxcli check script.mdl -p app.mpr --references
```

### 4. Common Error Patterns

| Error Message | Likely Cause | Fix |
|---------------|--------------|-----|
| `mismatched input 'set'` after `call microflow` | SET not valid with CALL | Use `$var = call microflow ...` |
| `mismatched input 'create'` | Structural keyword as identifier | Use `"create"` (quoted) or rename |
| `no viable alternative at input` | Unsupported syntax | Check supported statements list |
| `microflow not found` | Referenced before created | Move microflow definition earlier or check spelling |
| `page not found` | Page doesn't exist | Check qualified name with `--references` |
| `entity not found` | Typo or wrong module | Use fully qualified name |

## Validation Workflow

### Before Writing MDL

1. **Read the skill files:**
   ```bash
   cat .claude/skills/write-microflows.md
   cat .claude/skills/overview-pages.md
   ```

2. **Check help for specific syntax:**
   ```bash
   ./bin/mxcli syntax microflow
   ./bin/mxcli syntax page
   ./bin/mxcli syntax entity
   ```

### After Writing MDL

1. **Save to a file:**
   ```bash
   cat > script.mdl << 'EOF'
   -- Your MDL here
   EOF
   ```

2. **Run syntax check:**
   ```bash
   ./bin/mxcli check script.mdl
   ```

3. **If errors, check specific syntax:**
   ```bash
   ./bin/mxcli syntax keywords    # Reserved words
   ./bin/mxcli syntax microflow   # microflow syntax
   ```

4. **Run reference check (with project):**
   ```bash
   ./bin/mxcli check script.mdl -p app.mpr --references
   ```

5. **Execute only after all checks pass:**
   ```bash
   ./bin/mxcli exec script.mdl -p app.mpr
   ```

## Script Execution Behavior

**IMPORTANT: Script execution is atomic per statement, NOT per script.**

When a script fails on statement N, statements 1 through N-1 have already been committed:

```
Statement 1: create module ✓ (committed)
Statement 2: create entity ✓ (committed)
Statement 3: create association ✓ (committed)
Statement 4: create view entity ✗ (failed - execution stops here)
Statement 5: create page (never executed)
```

**Recommendations:**
1. Split scripts into phases when experimenting with uncertain syntax
2. Use `create or replace` to make scripts idempotent
3. Test new syntax patterns with minimal scripts first
4. Keep a backup of your project before running large scripts

## Script Organization

Organize scripts in dependency order:

```mdl
-- check-skip: illustrative ordering example; the PHASE 5 page block uses
-- shorthand pseudo-syntax (layout/title/parameter/widgets) for brevity, not
-- runnable MDL. See create-page.md for the real page syntax.
-- ============================================
-- PHASE 1: Enumerations (no dependencies)
-- ============================================
create enumeration Module.Status (
  Active 'Active',
  Inactive 'Inactive'
);
/

-- ============================================
-- PHASE 2: Entities (depend on enumerations)
-- ============================================
create persistent entity Module.Customer (
  Name: string(200),
  status: Module.Status
);
/

-- ============================================
-- PHASE 3: Associations (depend on entities)
-- ============================================
create association Module.Order_Customer
from Module.Order to Module.Customer
type reference;
/

-- ============================================
-- PHASE 4: Microflows (depend on entities)
-- ============================================
create microflow Module.ACT_Save ($Customer: Module.Customer)
returns boolean as $success
begin
  declare $success boolean = false;
  commit $Customer;
  set $success = true;
  return $success;
end;
/

-- ============================================
-- PHASE 5: Pages (depend on microflows)
-- ============================================
create page Module.Customer_Edit
layout Atlas_Default
title 'Edit Customer'
parameter $Customer: Module.Customer
widgets (
  -- Can reference microflows created in Phase 4
  button 'Save' call microflow Module.ACT_Save (Customer = $Customer)
);
/
```

## Troubleshooting Parse Errors

### Error: "snippet not found" / "page not found"

A reference to a document that hasn't been created yet in the script:

```
Error: snippet not found: MyModule.NavMenu
Error: page not found: MyModule.Customer_NewEdit
```

Script execution is sequential — each `CREATE` commits immediately. Forward references
fail because the target doesn't exist in the database at the moment the referencing
document is created.

**Fix options:**
1. **Reorder** — move the target document's `CREATE` earlier in the script (simplest fix)
2. **Placeholder pattern** — for circular dependencies (e.g. a snippet that shows pages
   that embed the snippet), create a minimal placeholder first, then create the referencing
   documents, then fill in the placeholder with `CREATE OR MODIFY` — which preserves the
   original UUID so all existing bindings remain valid
   (see [Resolve Forward References](./resolve-forward-references.md))

Declaration order that avoids most forward references:
```
enumerations → entities → snippets (placeholder) → pages → snippets (fill-in) → microflows → navigation
```

> **Never use `CREATE OR REPLACE` for the placeholder fill-in step.** OR REPLACE deletes
> the placeholder and creates a new document with a different UUID, silently breaking
> every page or snippet that references it.

### Error: "mismatched input 'X'"

The word `X` is either:
1. A reserved word - rename the identifier
2. Unsupported syntax - check the supported statements list
3. A typo - check spelling

### Error: "no viable alternative at input"

The parser expected something different:
1. Check for missing semicolons
2. Check for missing `end if`, `end loop`, etc.
3. Verify statement syntax against the reference

### Error: "extraneous input"

Extra tokens found:
1. Check for stray characters
2. Check for duplicate semicolons
3. Verify string quotes are balanced

## Studio Pro MCP — Verification Only

When Studio Pro's embedded MCP server is available **alongside** mxcli (i.e. you are
*not* using mxcli's own `--mcp` backend, but mxcli writes the `.mpr` directly while
Studio Pro is open), use Studio Pro MCP **only for reading and verification**. Never
author with `ped_create_document` / `ped_update_document` — mxcli owns the `.mpr`, and
mixing authoring tools corrupts intent and diverges UUIDs.

### Role split

| Task | Tool |
|------|------|
| Create/modify entities, microflows, pages, nanoflows, nav | mxcli MDL |
| Verify CE errors after exec | `ped_check_errors` |
| Inspect widget tree / microflow body detail | `ped_read_document` |
| Check if a document exists before creating | `ped_find_document` |
| Full model validation | `./mxcli docker check` |

### Studio Pro reads its in-memory model, not the file — a flush IS needed

This is the opposite of what you might expect. mxcli writes directly to the `.mpr`
SQLite file, but **Studio Pro serves `ped_*` reads from its in-memory model**, which
does not hot-reload when an external process changes the file. So after `mxcli exec`:

- `ped_read_document` / `ped_check_errors` will show the **stale** pre-exec model until
  Studio Pro re-scans — call `refresh_project` first (or reload the project in the UI).
- **Hazard:** if Studio Pro later saves on its own, it overwrites mxcli's disk write with
  its in-memory copy, silently discarding your MDL changes.

**Safest practice:** don't keep the same project open-and-saving in Studio Pro while
mxcli writes it. Either close (or don't save in) Studio Pro during MDL authoring, or
`refresh_project` after every `mxcli exec` before verifying. If you need both writing
*and* a live Studio Pro, use mxcli's `--mcp` backend (which authors *through* Studio
Pro) instead of writing the file directly.

### Step 6: Post-execution verification (add to the workflow above)

After `./mxcli exec script.mdl -p app.mpr` succeeds:

1. `refresh_project` (Studio Pro MCP) so the in-memory model reflects the new file.
2. `ped_check_errors` on each created/modified document for CE errors.

> **Do not treat an empty `DESCRIBE` as proof of a dropped construct.** `DESCRIBE`
> renders from the MDL emitter, which does not yet render every activity/widget type
> (e.g. Java/JavaScript action calls, exclusive splits, some nanoflow buttons). The
> construct may be present in the model even when `DESCRIBE` omits it. To tell a real
> write-drop from an emitter gap, confirm with `ped_read_document` (the live model) or
> `./mxcli docker check` — only flag an engine bug once the live model is also missing it.

## Related Skills

- [/write-microflows](./write-microflows.md) - Detailed microflow syntax
- [/overview-pages](./overview-pages.md) - Page building syntax
- [/resolve-forward-references](./resolve-forward-references.md) - Placeholder pattern and declaration ordering
- [/migrate-oracle-forms](./migrate-oracle-forms.md) - Migration-specific guidance
