# Diff Script

Compare an MDL script against the current state of a Mendix project to see what would change.

## Commands

```bash
# Unified diff (default) - traditional +/- format
mxcli diff -p app.mpr changes.mdl

# Side-by-side comparison
mxcli diff -p app.mpr changes.mdl --format side

# Structural summary
mxcli diff -p app.mpr changes.mdl --format struct

# With color output
mxcli diff -p app.mpr changes.mdl --color

# Side-by-side with custom width
mxcli diff -p app.mpr changes.mdl --format side --width 140
```

## Output Formats

### Unified (default)

Traditional diff format showing `+` for additions and `-` for removals:

```diff
--- Entity.MyModule.Customer (current)
+++ Entity.MyModule.Customer (script)
@@ -1,5 +1,6 @@
 CREATE PERSISTENT ENTITY MyModule.Customer (
   Name: String(100) NOT NULL,
-  Email: String(200)
+  Email: String(200) NOT NULL,
+  Phone: String(20)
 );
```

### Side-by-Side (--format side)

Two-column comparison showing current vs proposed:

```
Entity.MyModule.Customer
──────────────────────────────────────────────────────────────────
Current                              │ Script
──────────────────────────────────────────────────────────────────
  Email: String(200)                 │   Email: String(200) NOT NULL,  ~
                                     │   Phone: String(20)             +
```

### Structural (--format struct)

Summary of changes by element type:

```
Entity: MyModule.Customer
  ~ Attribute Email: changed
  + Attribute Phone: String(20)

Entity: MyModule.Order
  + New
```

## What Gets Compared

- **Entities**: Attributes, constraints, indexes, documentation
- **Enumerations**: Values and captions
- **Associations**: Type, owner, delete behavior
- **Microflows**: Parameters, return type, body statements

## Summary Output

Every diff ends with a summary:

```
Summary: 2 new, 3 modified, 5 unchanged
```

## Use Cases

1. **Preview changes** before executing a script
2. **Review modifications** in a pull request
3. **Audit** what an MDL script will modify
4. **Documentation** of changes between versions

## Tips

- Use `--color` for terminal output to easily spot changes
- Use `--format struct` for a quick overview of what changes
- Use `--format side` when comparing large objects
- Combine with `mxcli check` to validate syntax first
