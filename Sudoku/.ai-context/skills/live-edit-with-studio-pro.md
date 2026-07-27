# Live-Editing an Open Studio Pro Project with mxcli (MCP)

Use mxcli to change the model **while Studio Pro has the project open**, with edits
appearing live in Studio Pro — no save-and-reopen cycle. This is the workflow when
Claude Code runs on the same machine as Studio Pro (e.g. an in-IDE terminal).

## When to use this skill

- Studio Pro is open on the project and you want mxcli changes to show up live.
- mxcli and Studio Pro run on the **same machine** (same `localhost`).

If Studio Pro is **not** open, use the normal file-based flow instead
(`mxcli -p app.mpr -c "..."` with no `--mcp`), which edits the `.mpr` on disk.

## How it works (hybrid: local reads, live writes)

- **Reads** come from the local `.mpr` you pass with `-p`.
- **Writes** go to Studio Pro's live, in-memory model via its built-in MCP server.
- Therefore **`-p` MUST be the exact project Studio Pro currently has open**, or
  reads and writes will describe different projects.

## Connect

Studio Pro's MCP server listens on `localhost:7782` and requires the HTTP
`Host` header to be `localhost` (a DNS-rebinding guard). Same-machine, **no
port-forwarding/socat is needed**:

```bash
mxcli --mcp http://localhost/mcp --mcp-dial localhost:7782 \
      -p /path/to/app.mpr \
      -c "create entity MyModule.Customer"
```

`--mcp-dial localhost:7782` keeps the `Host` header `localhost` while dialing the
port. (Plain `--mcp http://localhost:7782/mcp` may also work if your Studio Pro
accepts a port-suffixed `Host` — try it; fall back to the `--mcp-dial` form if it
is rejected.)

Run a script the same way: `mxcli --mcp http://localhost/mcp --mcp-dial localhost:7782 -p app.mpr exec changes.mdl`.

## What you can change via MCP — check first

**What's authorable over MCP depends on the Studio Pro version**, because the
underlying capability surface grows per release. Before generating MDL for live
editing, ask the connected server what it supports — don't guess:

```bash
mxcli mcp capabilities -p /path/to/app.mpr --mcp http://localhost/mcp --mcp-dial localhost:7782
```

It prints, for *this* server: what's authorable (modules, entities + ALTER,
associations, enumerations, constants, microflows, pages + ALTER PAGE, workflows,
view entities, documents into folders), what's **not** (e.g. nanoflows, Java
actions, business-event services, security, navigation, MOVE/re-parent, attribute
type change — hard PED limits), and the live tool list. Treat anything reported as
not authorable as off-limits over MCP — do it in Studio Pro or against the on-disk
`.mpr` instead.

New modules and their dependents resolve within the same run, so
`create module X; create enumeration X.Status (...)` works in one script. Place a
document in a folder at create time (`create microflow X.MF folder 'A/B'`), since
MOVE can't re-parent over MCP.

## Two MCP servers — use the built-in one by default

The machine may run two MCP servers:

- **Studio Pro built-in (port 7782)** — model authoring. **Use this by default.**
- **Concord (port 7783)** — a temporary gap-filler with operational/refactor tools
  (`delete_document`, `save_all`, `run_app`, `check_model`). **Only** reach for
  Concord when the built-in server lacks the capability you need.

## Caveats

- **Writes are unsaved.** They land in Studio Pro's in-memory model (shown as
  unsaved). Save in Studio Pro to persist to disk.
- **No DROP of standalone documents** (enumeration / microflow / page) through the
  built-in server — it has no delete tool. Remove them in Studio Pro (or via
  Concord's `delete_document`).
- **`-p` must match the open project.** A mismatched `-p` silently reads the wrong
  model.

## Verify your change

Read it back through the same connection (in-session edits are visible), or look
in Studio Pro:

```bash
mxcli --mcp http://localhost/mcp --mcp-dial localhost:7782 -p app.mpr -c "show entities in MyModule"
```
