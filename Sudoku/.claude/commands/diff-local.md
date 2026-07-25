# Diff Local Changes

Compare local (uncommitted) changes in mxunit files against a git reference to see what has changed.

**Note:** This command only works with MPR v2 format (Mendix 10.18+) which stores units in the `mprcontents/` folder.

## Commands

```bash
# Show uncommitted changes vs HEAD (default)
mxcli diff-local -p app.mpr

# Compare against a specific commit
mxcli diff-local -p app.mpr --ref HEAD~1

# Compare against a branch
mxcli diff-local -p app.mpr --ref main

# Compare against a tag
mxcli diff-local -p app.mpr --ref v1.0.0

# With structural format
mxcli diff-local -p app.mpr --format struct

# Side-by-side comparison
mxcli diff-local -p app.mpr --format side

# With color output
mxcli diff-local -p app.mpr --color
```

## Output Formats

### Unified (default)

Traditional diff format showing `+` for additions and `-` for removals:

```diff
--- Microflow.MyModule.ProcessOrder (current)
+++ Microflow.MyModule.ProcessOrder (script)
@@ -1,5 +1,6 @@
 CREATE MICROFLOW MyModule.ProcessOrder (
   $order: MyModule.Order
+  $discount: Decimal
 )
 RETURNS Void
```

### Side-by-Side (--format side)

Two-column comparison showing git vs local:

```
Microflow.MyModule.ProcessOrder
──────────────────────────────────────────────────────────────────
Current                              │ Script
──────────────────────────────────────────────────────────────────
  $order: MyModule.Order             │   $order: MyModule.Order
                                     │   $discount: Decimal         +
```

### Structural (--format struct)

Summary of changes by element type:

```
Microflow: MyModule.ProcessOrder
  + Parameter $discount: Decimal
  ~ Lines: 2 lines added

Entity: MyModule.Customer
  + Attribute Phone: String(20)
```

## How It Works

1. **Finds changed files**: Uses `git diff --name-status` to identify modified `.mxunit` files in the `mprcontents/` folder
2. **Reads both versions**: Current version from disk, git version using `git show`
3. **Parses BSON**: Extracts the unit type and content from the binary BSON format
4. **Generates MDL**: Converts both versions to MDL for human-readable comparison
5. **Shows diff**: Outputs the differences in the selected format

## Supported Unit Types

The command generates MDL representations for:

- **Entities**: Shows attributes, constraints, and entity type
- **Microflows**: Shows parameters and return type
- **Nanoflows**: Shows parameters and return type
- **Enumerations**: Shows values and captions
- **Pages**: Shows title and layout reference
- **Snippets**: Shows basic structure
- **Layouts**: Shows basic structure
- **Modules**: Shows module name

Other unit types show a generic representation with the type name.

## Summary Output

Every diff ends with a summary:

```
Summary: 2 new, 3 modified, 1 deleted
```

## Use Cases

1. **Review changes** before committing to version control
2. **Understand modifications** made by Studio Pro
3. **Audit changes** between versions
4. **Debug issues** by comparing working vs previous state

## Tips

- Use `--color` for terminal output to easily spot changes
- Use `--format struct` for a quick overview of what changed
- Use `--format side` when comparing large objects with subtle differences
- Use `--ref HEAD~5` to see what changed in the last 5 commits
- Use `--ref feature-branch` to compare against a different branch

## Requirements

- MPR v2 format (Mendix 10.18+)
- Git repository with the project under version control
- The `mprcontents/` folder must be tracked by git
