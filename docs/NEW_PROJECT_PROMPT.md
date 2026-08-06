# Initialization prompt for a new mxcli workspace

Paste the block below as the **first message** of a fresh Claude Code web
session to bootstrap another container like this one. It covers **phase 1 only**
— the toolchain, no Mendix app — because that part has to be right before
anything else works, and keeping it separate is what made
[`scripts/setup-tools.sh`](../scripts/setup-tools.sh) genuinely idempotent
instead of entangled with project state.

Before starting the session, set the hub credentials in the Claude Code
**environment configuration** (not in the prompt, and not in a committed file):
`MXCLI_HUB_URL`, `MXCLI_HUB_KEY`, `MXCLI_HUB_SECRET`.

---

```
You are setting up a Mendix development workspace in this container. Everything in
this project is authored through mxcli/MDL — never by hand-editing the .mpr and
never in Studio Pro.

PHASE 1 — TOOLCHAIN ONLY. Do not scaffold a Mendix app yet. Set up the toolchain,
verify it, commit the setup, then STOP and report.

## What to install

1. Detect what the base image already provides — do not reinstall it. Expect
   roughly: Go 1.24.x, JDK 21, Node 20+, PostgreSQL 16, and Chromium already
   present at /opt/pw-browsers/chromium (with PLAYWRIGHT_BROWSERS_PATH and
   PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD already set — never run `playwright install`).
   Report the versions you find.

2. Pin ANTLR 4.13.1 — mxcli's grammar build needs the `antlr4` command:
   - jar at /opt/antlr/antlr-4.13.1-complete.jar
   - a shim at /usr/local/bin/antlr4 that execs `java -jar` on it
   Any other ANTLR version will fail the build.

3. Build mxcli from source: clone https://github.com/ako/mxcli.git at main,
   `go build`, install to /usr/local/bin/mxcli. Set GOTOOLCHAIN=auto so the
   go.mod toolchain directive is honoured. Record the main HEAD SHA — you will
   need it to know whether a later rebuild is required.

4. Pre-cache the Mendix build engine and runtime for the version you will target
   (11.13.0 unless told otherwise) so the first build isn't a cold download.

5. Verify, and fail loudly if anything is missing: mxcli runs, antlr4 shim +
   jar present, mx validator present, mxbuild engine present, Mendix runtime
   present, postgres server present, chromium present. Print a version summary
   at the end.

## What to commit

- `scripts/setup-tools.sh` — one idempotent, re-runnable script that does all of
  the above. Detect-then-install: skip the jar if present, skip the mxcli build
  if the installed binary already matches main HEAD, skip the engine/runtime
  download if already cached. It must be safe to run on every session start.
- `.claude/settings.json` — a SessionStart hook that runs it.
- `TOOLING.md` — how the toolchain is re-established and why (the container is
  ephemeral: nothing under /opt, ~/.mxcli, or the built binaries survives, so
  reproducibility comes from committed files, not installed state).
- `.gitignore`.

Do NOT commit: binaries, the mxcli clone, the ANTLR jar, *.mda, or deployment/.

## Hook wiring — important

When you later add a script that launches the app, put it in the SAME hook
command as the setup script, chained with `&&`:

    "command": "bash \"$CLAUDE_PROJECT_DIR/scripts/setup-tools.sh\" && bash \"$CLAUDE_PROJECT_DIR/scripts/run-app.sh\""

Two entries in one SessionStart hooks array run CONCURRENTLY, not sequentially.
That race will launch the app on the previous mxcli binary while the rebuild is
still in flight, and the symptom is invisible (the process just holds a deleted
inode).

## Ground rules for all later phases

- mxcli's default engine is `modelsdk`. Do NOT use `--engine legacy`.
- Author everything in .mdl files under `<App>/mdlsource/`, numbered so they
  apply in dependency order, and re-apply them from scratch rather than patching
  the .mpr.
- `mxcli -c "REFRESH CATALOG FULL"` — plain REFRESH leaves activities_data and
  refs empty.
- Never run `mx check` while a `--watch` loop is live; it wedges the loop.
- Use anchored pgrep/pkill patterns (e.g. `^mxcli run`) — a bare `pgrep -f mxcli`
  matches your own shell and kills the command chain.
- Hub credentials (MXCLI_HUB_URL, MXCLI_HUB_KEY, MXCLI_HUB_SECRET) come from the
  Claude Code environment configuration, never from a committed file. A gitignored
  file would not survive container recycling. MXCLI_HUB_KEY must be minted in a
  browser at https://hub.mxcli.org/cli — the container cannot reach GitHub's
  OAuth device-flow endpoints, so `mxcli auth hub login` cannot complete here.
- Keep a FINDINGS.md from the first session: every mxcli bug, surprise, or
  workaround, numbered, with the exact command and output. It is the main
  deliverable alongside the app.

Now do phase 1, then stop and report the versions plus the mxcli HEAD SHA.
```

---

## Why the prompt says what it says

Two points are drawn from mistakes made in this repo rather than from how the
setup reads in hindsight:

- **The hook race is real.** This repo originally listed the setup and launch
  scripts as two entries in one `SessionStart` array, and they fired in parallel.
  The app came up on a deleted `/usr/local/bin/mxcli` inode while the rebuild was
  still running, and nothing in the logs said so — only
  `readlink /proc/<pid>/exe` showed it. Chain them with `&&`;
  [`.claude/settings.json`](../.claude/settings.json) now does.
- **`auth hub login` cannot complete in the container.** The egress gateway
  blocks GitHub's OAuth device-flow endpoints, so the API key has to be minted in
  a browser and handed in through the environment.

Later phases (scaffolding the app, the observability scripts under
[`scripts/`](../scripts), the hub preview) are best driven conversationally
rather than from one large prompt — see [`README.md`](../README.md) and
[`FINDINGS.md`](../FINDINGS.md) for what those sessions produced here.
