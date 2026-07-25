# Tooling — mxcli (MDL) Mendix development workspace

This repository is set up as a **Mendix-app development workspace driven by
[`mxcli`](https://github.com/ako/mxcli) (MDL)**, with mxcli **built from source**.

No Mendix project has been scaffolded yet — this repo currently contains only
the toolchain + setup automation. See [Next step](#next-step) to bootstrap the app.

## How the toolchain is (re)established

The runtime container is **ephemeral** — it is reclaimed after inactivity and
re-cloned fresh next session. Nothing under `/opt`, `~/.mxcli`, or the built
binaries survives. Reproducibility therefore comes from committed files, not
installed state:

- [`scripts/setup-tools.sh`](scripts/setup-tools.sh) — idempotent, re-runnable
  installer that pins ANTLR, builds mxcli from source, and pre-caches the Mendix
  build engine + runtime.
- [`.claude/settings.json`](.claude/settings.json) — a **`SessionStart` hook**
  that runs `scripts/setup-tools.sh` automatically at the start of every session,
  so the toolchain rebuilds itself.

To (re)establish everything manually at any time:

```bash
bash scripts/setup-tools.sh
```

The script is detect-then-install: it skips work already done (jar present,
mxcli already at `main` HEAD, engine/runtime already cached).

## Installed versions

| Component | Version | Notes |
|-----------|---------|-------|
| **mxcli** | `main` @ `2a4494a` | Built from source; see pinned SHA below. |
| **Mendix (MxBuild + runtime)** | `11.12.1` | Pre-cached under `~/.mxcli/`. Engine = `modelsdk` (default). |
| **ANTLR** | `4.13.1` (**pinned**) | Jar at `/opt/antlr/antlr-4.13.1-complete.jar`; `antlr4` shim first on PATH. Must match the `antlr4-go/antlr v4.13.1` Go runtime. |
| **Go** | `go1.24.7` present; toolchain **`go1.26.5`** auto-fetched | `go.mod` pins `go 1.26.0` / `toolchain go1.26.5`; `GOTOOLCHAIN=auto` lets `go build` fetch it. |
| **JDK** | `21.0.10` | Needed by ANTLR and the Mendix runtime. |
| **Node** | `v22.22.2` | For Playwright screenshot verification. |
| **Chromium** | pre-installed | `$PLAYWRIGHT_BROWSERS_PATH/chromium` (`/opt/pw-browsers/chromium`). Verified, not reinstalled. |
| **PostgreSQL** | `16.13` server | `/usr/lib/postgresql/16/bin` — needed by `mxcli run --local --ensure-db`. |

### Pinned mxcli commit (reproducible build)

```
Repository: https://github.com/ako/mxcli  (branch: main)
Commit:     2a4494ac2cf98782000b055a5f27794fac2e7e13
Short SHA:  2a4494a
```

`scripts/setup-tools.sh` tracks `main` HEAD and rebuilds when the installed
binary's SHA differs. To reproduce **this exact build**, check out the commit
above in `/opt/mxcli-src` before running `make build`.

## Cache & install locations (not committed)

| Path | Contents |
|------|----------|
| `/opt/mxcli-src` | mxcli source clone (git). |
| `/usr/local/bin/mxcli` | Installed mxcli binary. |
| `/opt/antlr/antlr-4.13.1-complete.jar` | Pinned ANTLR jar. |
| `/usr/local/bin/antlr4` | Shim → `java -jar` the pinned jar. |
| `~/.mxcli/mxbuild/11.12.1/modeler/{mx,mxbuild}` | Mendix validator + build engine. |
| `~/.mxcli/runtime/11.12.1` | Mendix runtime (for `mxcli run --local`). |

All of the above are `.gitignore`d and rebuilt by the setup script.

## Next step

This session installed the toolchain **only**. A follow-up session will scaffold
the actual Mendix app. The single command to bootstrap the project:

```bash
mxcli new <app-name> --version 11.12.1
```

`mxcli new` downloads MxBuild for the version (already cached), creates a blank
Mendix project via `mx create-project`, and initializes AI tooling. Use the
default `modelsdk` engine — do **not** pass `--engine legacy`.
