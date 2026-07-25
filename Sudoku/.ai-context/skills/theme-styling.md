# Theme & Styling — SCSS Workflow and Caveats

## When to Use This Skill

Use this skill when working with:
- SCSS compilation, `custom-variables.scss`, or `themesource/` directories
- CSS hot-reload during Docker development
- Debugging styling crashes or design property issues

For **MDL styling commands** (`show design properties`, `describe styling`, `alter styling`, inline `designproperties:`, `update widgets`), see:
- Existing proposal: `docs/11-proposals/page-styling-support.md`
- Working examples: `mdl-examples/doctype-tests/12-styling-examples.mdl` (595 lines)
- Implementation: `mdl/executor/cmd_styling.go`, `mdl/executor/theme_reader.go`

## SCSS Compilation Chain

### Directory Structure

```
MyProject/
├── theme/                          # project-level overrides
│   └── web/
│       ├── main.scss               # SCSS entry point (import chain)
│       ├── custom-variables.scss   # project variable overrides
│       ├── exclusion-variables.scss # Exclude unwanted Atlas components
│       └── settings.json           # Theme settings
│
├── themesource/                    # module-level theme definitions
│   ├── atlas_core/                 # base framework (always present)
│   │   └── web/
│   │       ├── design-properties.json  # widget design properties
│   │       ├── variables.scss          # Color/spacing/font variables
│   │       └── ...                     # Component SCSS files
│   ├── datawidgets/                # DataGrid2, gallery, etc.
│   ├── atlas_web_content/          # Web content styles
│   └── <module_name>/              # Each module can contribute styles
│       └── web/design-properties.json
│
└── theme-cache/web/                # Compiled CSS output (build artifact)
```

### Compilation Order

`atlas_core/web/main.scss` imports in order:
1. Default variables (`atlas_core`)
2. Exclusion variables (disable Atlas components)
3. Project custom variables (`theme/web/custom-variables.scss`)
4. Bootstrap framework
5. MXUI components
6. Core styles (base, animations, spacing, flex)
7. Widget-specific styles
8. Module-specific styles from `themesource/*/web/*.scss`

Variables declared earlier are overridden by later declarations (with `!default` flag). This means `custom-variables.scss` overrides `atlas_core/web/variables.scss` values.

## CSS Hot-Reload Workflow

For theme/styling changes during Docker development:

```bash
# 1. Compile SCSS into deployment package (~55s)
mxcli docker build -p app.mpr

# 2. Push compiled CSS to browsers (instant, no page reload)
mxcli docker reload -p app.mpr --css
```

The `--css` flag calls the M2EE `update_styling` action, which pushes CSS via WebSocket to all connected browsers. **It does NOT compile SCSS** — always run `docker build` first.

For non-CSS changes (Class, Style, DesignProperties on widgets), use normal reload:
```bash
mxcli docker reload -p app.mpr
```

## Caveats

### DYNAMICTEXT + Style Crash

**Never** apply `style` directly to a DYNAMICTEXT widget — it crashes MxBuild with a NullReferenceException. Wrap in a CONTAINER:

```sql
-- WRONG: crashes MxBuild
dynamictext txt (content: 'Hello', style: 'color: red;')

-- CORRECT: style the container
container ctn (style: 'color: red;') {
  dynamictext txt (content: 'Hello')
}
```

This also applies to `alter styling` and `alter page set style` — never target a DYNAMICTEXT widget with Style.

### Design Property Keys Are Case-Sensitive

Keys must match the `name` field in `design-properties.json` exactly:
```sql
-- CORRECT
designproperties: ['Spacing top': 'Large']

-- WRONG (case mismatch — silently ignored)
designproperties: ['spacing top': 'Large']
```

### Compound (Nested) Design Properties

Besides **flat** properties (a key with a single value — an option/dropdown
string or a toggle), `designproperties:` also supports **compound** properties:
one whose value is itself a set of sub-properties (e.g. Atlas's `Spacing` →
`margin-top`, `margin-bottom`, …). A compound value is written as a nested list:

```sql
designproperties: [
  'Column gap': 'Medium',                                       -- flat option
  'Cards style': ON,                                            -- flat toggle
  'Spacing': ['margin-top': 'Large', 'margin-bottom': 'Medium'] -- compound
]
```

Supported on the **modelsdk** (`.mpr`) and **MCP** (live Studio Pro) backends.
Sub-property keys are case-sensitive, same as flat keys.

### ALTER STYLING Limitation with Builder-Created Pages

`alter styling` cannot find widgets in pages created by the MDL page builder because `walkPageWidgets` traverses `LayoutCall.Arguments` but the page parser doesn't fully reconstruct the widget tree when re-reading builder-created pages. These commands work on pages originally created in Studio Pro.

## Checklist

- [ ] Never apply `style` directly to DYNAMICTEXT — wrap in a CONTAINER
- [ ] Design property keys are case-sensitive — match `design-properties.json` exactly
- [ ] Compound/nested design properties (e.g. grouped Spacing) use a nested list: `'Spacing': ['margin-top': 'Large']`
- [ ] For CSS changes, run `docker build` then `docker reload --css`
- [ ] Use `describe styling` to verify changes after modification
- [ ] Check `docs/11-proposals/page-styling-support.md` for BSON format details
