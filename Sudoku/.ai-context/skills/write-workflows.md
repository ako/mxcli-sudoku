# Mendix Workflows Skill

Guidance for **authoring** workflows in Mendix projects with MDL — not just
reading them. `CREATE WORKFLOW` / `DROP WORKFLOW` / `ALTER WORKFLOW` are fully
supported and build in Studio Pro. Workflows are **not** read-only in mxcli; do
not punt workflow creation to Studio Pro.

## When to Use This Skill

- Creating a business process: approvals, reviews, multi-step tasks with user
  interaction, timers, and parallel branches.
- Adding/removing/reordering activities in an existing workflow (`ALTER WORKFLOW`).
- Regenerating a workflow from `DESCRIBE WORKFLOW` output (round-trippable).

A workflow is a `Workflows$Workflow` unit driven by a **context entity**: the
persistent entity each workflow instance is about (the `Expense` being approved,
the `LeaveRequest` being reviewed). User tasks render a page bound to
`System.WorkflowUserTask`.

## Syntax — CREATE WORKFLOW

The header options are **order-sensitive** (parameter → display → description →
export level → overview page → due date), and the body **must** close with
`END WORKFLOW`.

```sql
create workflow Module.ApprovalFlow
  parameter $Context: Module.Request        -- REQUIRED: must be a $-variable + context entity
  display 'Request Approval'                 -- optional human-readable name
  description 'Approves incoming requests'   -- optional
  export level Hidden                        -- optional: Hidden | API (default Hidden)
  overview page Module.WF_Overview           -- optional admin overview page
begin
  -- activities here, each terminated with ;
end workflow;
```

**Two gotchas that trip up first attempts:**

- `PARAMETER` takes a **`$`-variable then a context entity**: `parameter $Context:
  Module.Entity`. `parameter Module.Entity` and `parameter name: Module.Entity`
  both fail (`expecting VARIABLE`).
- The body closer is `end workflow`, **not** `end`. `end;` fails (`missing
  WORKFLOW`).

`create or replace workflow …` and `create or modify workflow …` are supported.

## Activities

Every activity statement ends with `;`. Blocks `{ … }` nest a sub-flow.

```sql
create or replace workflow Module.ApprovalFlow
  parameter $Context: Module.Request
begin
  -- User task: renders a page, offers named outcomes (branches)
  user task Review 'Review the request'
    page Module.ReviewPage
    targeting users microflow Module.ACT_Reviewers   -- or: targeting users xpath '[Active = true()]'
    description 'Please review'
    outcomes
      'Approve' { call microflow Module.ACT_Process; }
      'Reject'  { call microflow Module.ACT_Notify; };

  -- Multi user task: same clauses, one task per targeted user
  multi user task GroupSignoff 'Group sign-off'
    page Module.ReviewPage
    outcomes 'Done' { };

  -- Call a microflow (server logic); optional parameter mapping + outcomes
  call microflow Module.ACT_Validate
    with (Module.ACT_Validate.Item = '$workflowContext');

  -- Decision: a boolean or enum exclusive split
  decision '$workflowContext/Total > 1000'
    outcomes
      true  -> { call microflow Module.ACT_Escalate; }
      false -> { call microflow Module.ACT_AutoApprove; };

  -- Parallel split: independent branches run concurrently
  parallel split
    path 1 { call microflow Module.ACT_Notify; }
    path 2 { call microflow Module.ACT_Log; };

  -- Wait for a timer, then continue (duration is a Mendix expression)
  wait for timer 'addHours([%CurrentDateTime%], 1)';

  -- Wait for an external notification (e.g. an event)
  wait for notification;

  -- Jump back to an earlier activity by name (a loop)
  jump to Review;

  -- Call a sub-workflow
  call workflow Module.SubProcess comment 'delegate';

  -- Sticky-note annotation
  annotation 'Escalation path per policy 4.2';
end workflow;
```

**Boundary events** attach a timer to a user task / call-microflow / wait:

```sql
create or replace workflow Module.WithBoundary
  parameter $Context: Module.Request
begin
  user task Review 'Review'
    page Module.ReviewPage
    outcomes 'Done' { }
    boundary event interrupting timer 'addDays([%CurrentDateTime%], 3)' {
      call microflow Module.ACT_Escalate;
    };
end workflow;
```

## DROP WORKFLOW

```sql
drop workflow Module.ApprovalFlow;
```

## ALTER WORKFLOW

In-place edits go through the workflow mutator — no full rewrite. Supports
`SET` properties, and `INSERT` / `DROP` / `REPLACE` of activities, outcomes,
parallel paths, decision conditions, and boundary events. Reference an activity
by its name (or an auto-named one by its caption in quotes).

Each operation is its **own statement** — there is no `{ … }` wrapper, and `SET`
uses no `=` (`set display 'X'`, not `set display = 'X'`):

```sql
alter workflow Module.ApprovalFlow set display 'Updated Approval';
alter workflow Module.ApprovalFlow set activity Review page Module.AltReviewPage;
alter workflow Module.ApprovalFlow insert after Review call microflow Module.ACT_Log;
alter workflow Module.ApprovalFlow replace activity ACT_Validate with call microflow Module.ACT_Process;
```

Consecutive `set`s may chain in one statement:
`alter workflow Module.ApprovalFlow set display 'X' set description 'Y';`

See `mdl-examples/doctype-tests/24-workflow-examples.mdl` for the full ALTER
surface (insert path, drop path, insert condition, boundary events).

## DESCRIBE round-trip

`DESCRIBE WORKFLOW Module.Name` emits **executable, re-runnable** MDL — user
tasks, decisions, splits, jump-to targets, and wait activities all come back as
statements (not comments). You can learn the exact syntax by describing a
Studio-Pro-authored workflow, and `describe → drop → exec` reproduces a workflow
that builds. (The implicit start/end activities are omitted, as they are
re-synthesised on create.)

## Platform rules

- A user task needs a **task page** to be useful; without one Mendix flags the
  task (`CE1834`). Bind the page to `System.WorkflowUserTask`.
- A user task / decision with a single outcome and no activity can trip
  `CE1876` — give each branch a body or a distinct outcome.
- The context **Parameter entity must be persistent**.

## Validate before presenting

```bash
./bin/mxcli check script.mdl                      # syntax + activity grammar
./bin/mxcli check script.mdl -p app.mpr --references   # entity/page/microflow refs exist
```

Then `show workflows` (lists the workflow, its parameter entity, and activity
count) and, if Docker is available, `mxcli docker build -p app.mpr` for the full
Studio-Pro validation.
