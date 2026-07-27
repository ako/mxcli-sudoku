# Validate Project

Run Mendix's `mx check` command to validate the project for errors.

This is the same validation that Studio Pro performs - it checks for consistency errors (CE codes), warnings (CW codes), and other issues.

## Prerequisites

The `mx` command must be available. In a dev container, run `mxcli setup mxbuild -p app.mpr` to auto-download it.

**Where to find `mx`:**

| Environment | Path |
|-------------|------|
| Dev container | `~/.mxcli/mxbuild/{version}/modeler/mx` |
| Studio Pro install | `mx` (in PATH) |
| Manual download | `/path/to/mxbuild/modeler/mx` |

## Command

```bash
# In dev container (after mxcli setup mxbuild -p app.mpr)
~/.mxcli/mxbuild/*/modeler/mx check app.mpr

# Or use the integrated command (auto-downloads mxbuild)
mxcli docker check -p app.mpr

# With explicit path
/path/to/mxbuild/modeler/mx check /path/to/project.mpr
```

## Example Output

```
$ mx check MyApp.mpr
Mendix 10.6.0

Checking project...

MyFirstModule.Customer_Overview (Page):
  CE0123: The entity 'MyFirstModule.Customer' does not exist.

MyFirstModule.SaveCustomer (Microflow):
  CW0456: Variable '$customer' is declared but never used.

Found 1 error(s) and 1 warning(s)
```

## Common Error Codes

| Code | Type | Description |
|------|------|-------------|
| CE0xxx | Error | Consistency error - must be fixed |
| CW0xxx | Warning | Warning - should be reviewed |
| CD0xxx | Deprecation | Deprecated feature usage |

## When to Use

- After making changes with mxcli to verify they're valid
- Before committing changes to version control
- After merging branches to check for conflicts
- To diagnose issues reported in Studio Pro

## Workflow

1. Make changes with mxcli:
   ```sql
   CREATE ENTITY Sales.Product (...);
   ```

2. Disconnect to save changes:
   ```sql
   DISCONNECT;
   ```

3. Validate with mx check:
   ```bash
   mx check MyApp.mpr
   ```

4. Fix any errors and repeat

## Tips

- Run `mx check` after significant MDL changes
- Some warnings can be ignored (review case-by-case)
- Errors (CE codes) must be fixed before the project can run
- Use `mxcli check script.mdl` for MDL syntax validation (different from project validation)
