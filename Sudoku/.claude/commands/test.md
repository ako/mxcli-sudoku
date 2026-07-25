# Test App

Verify the running Mendix application using playwright-cli.

## Prerequisites

- App must be running: `mxcli docker run -p app.mpr --wait`
- playwright-cli installed (included in devcontainer)

## Session lifecycle

Manage the browser session across commands (attach/reuse, check, tear down):

```bash
mxcli playwright open -p app.mpr    # open or attach to the session
mxcli playwright status             # is it live? what page?
mxcli playwright close [--all]      # tear down
```

Typical loop: `open` once and log in, then iterate `mxcli playwright verify … --keep-open`.

## Quick Start

```bash
# Open browser and take snapshot
playwright-cli open http://localhost:8080
playwright-cli snapshot

# Verify a widget exists (page/DOM assertions run in page context -> eval)
playwright-cli eval "() => document.querySelector('.mx-name-widgetName') !== null"

# Take a screenshot
playwright-cli screenshot

# Close when done
playwright-cli close
```

## Login (Security Enabled)

```bash
playwright-cli open http://localhost:8080
playwright-cli eval "() => { document.querySelector('#usernameInput').value = 'MxAdmin' }"
playwright-cli eval "() => { document.querySelector('#passwordInput').value = 'AdminPassword1!' }"
playwright-cli eval "() => document.querySelector('#loginButton').click()"
playwright-cli eval "() => new Promise(r => setTimeout(r, 3000))"
playwright-cli state-save mendix-auth
```

## Full Workflow

```bash
# 1. Apply MDL changes
mxcli exec changes.mdl -p app.mpr

# 2. Build, start, and wait for runtime
mxcli docker run -p app.mpr --fresh --wait

# 3. Open browser and verify
playwright-cli open http://localhost:8080
playwright-cli snapshot
# ... interact and verify ...

# 4. Verify data persistence
mxcli oql -p app.mpr --json "SELECT Name FROM MyModule.Customer"

# 5. Close browser
playwright-cli close
```

## CI/CD Scripts

For regression testing, capture commands in shell scripts:

```bash
# Run a test script
bash tests/verify-customers.sh

# Run all test scripts
for f in tests/verify-*.sh; do bash "$f" || exit 1; done
```

## Tips

- Use `.mx-name-*` selectors from your MDL widget names — they are stable
- Use `eval "() => ..."` for page/DOM assertions (`run-code` runs in Node, where `document` is undefined); `throw new Error(...)` inside the function to fail under `set -e`
- Use `state-save`/`state-load` to persist login across verifications
- In the edit → re-verify loop, pass `mxcli playwright verify … --keep-open` so the next run reuses the warm, logged-in browser instead of cold-launching Chromium (drop any trailing `playwright-cli close` from reused scripts)
- Use `mxcli oql` for data assertions (no npm packages needed)
- The devcontainer ships only the headless shell (no display), so use `playwright-cli screenshot` (and `tracing-start`/`tracing-stop`) for visual debugging — headed mode needs the full Chromium build and a display
- See skill: test-app for full reference
