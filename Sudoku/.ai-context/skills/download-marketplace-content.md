# Download and Install Marketplace Content

This skill covers discovering, downloading, and installing Mendix Marketplace content (modules and widgets) with `mxcli marketplace`. These are **CLI commands**, not MDL statements.

## When to Use This Skill

- User wants to add a marketplace module or widget to a project
- User asks to download a specific `.mpk` (e.g. for CI, or to import in Studio Pro)
- User asks which versions of a marketplace item are compatible with their Mendix version
- User asks why a marketplace module did not update

## Prerequisites: Authenticate

Marketplace access needs a Mendix Personal Access Token (PAT), created at
<https://user-settings.mendix.com/> (Developer Settings → Personal Access Tokens).

```bash
mxcli auth login                 # interactive prompt for the PAT
mxcli auth login --token <PAT>   # non-interactive (CI)
export MENDIX_PAT=<PAT>          # or via environment
mxcli auth status                # verify it validates
```

Credentials are stored at `~/.mxcli/auth.json` (mode `0600`).

## Discover

```bash
mxcli marketplace search "database connector"   # find content by name/publisher
mxcli marketplace info 2888                      # details for a content id
mxcli marketplace versions 2888                  # available versions
mxcli marketplace versions 2888 --min-mendix 10.24.0   # compatible versions only
```

The numeric **content id** (from `search`/`info`) is what `download`/`install` take.

**Search caching.** The Content API has no server-side search, so the first `search`
fetches the whole catalog (tens of seconds) and caches it under `~/.mxcli/` for 24h;
later searches are instant. If the first search seems slow, it is scanning the catalog —
let it finish. Pass `--refresh` to bypass the cache and re-fetch (e.g. for a brand-new
module). If `search` returns nothing, the content may be private or named differently —
look it up by id with `info <id>` (ids come from the marketplace URL `.../link/component/<id>`).

## Download a `.mpk` to disk

```bash
mxcli marketplace download 2888                          # latest, CDN filename
mxcli marketplace download 2888 --version 7.0.2 -o dbc.mpk   # specific version + path
```

Use this when you only want the file (e.g. to commit to `mx-modules/`, or import in Studio Pro yourself).

## Install into a project

```bash
mxcli marketplace install <content-id> -p app.mpr [--version X.Y.Z]
```

`install` is **type-aware**:

| Content type | Behavior |
|---|---|
| **Widget** | Copied into `widgets/` (overwrites on update). Reload in Studio Pro, or run `mxcli docker check`/`build` to normalize (v2-safe). Do **not** run bare `mx update-widgets` on an `mprcontents/` project — it converts to v1 and deletes `mprcontents/`. |
| **Module** (new) | Imported via `mx module-import` — needs a matching mxbuild (`mxcli setup mxbuild -p app.mpr`). |
| **Module** (already present) | **Reported, not modified** — see the caveat below. |
| Theme / Starter App / Sample | Downloaded with import instructions (import via Studio Pro). |

## IMPORTANT: module updates are not automatic

If the module is **already in the project**, `install` will NOT replace it. It reports the installed vs target version and stops. Do not try to force an update by deleting the module and re-importing — that is unsafe:

1. **Local edits** to the module would be discarded.
2. **Persistent-entity `$ID`s** would change. The runtime database keys data by entity ID, so a re-import makes the runtime treat the entities as new ones and **data is lost**.

Studio Pro's Marketplace **Update** does an ID-preserving merge that the CLI cannot. For module updates, tell the user to update via Studio Pro.

## Notes

- `install` requires `-p <app.mpr>`; `download` does not (it just fetches the file).
- Both require `mxcli auth login` first; an expired/missing PAT gives an auth error with a login hint.
