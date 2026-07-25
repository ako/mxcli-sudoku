---
name: mendix-custom-widgets
description: Use when writing MDL for GALLERY, COMBOBOX, or third-party pluggable widgets in CREATE PAGE / ALTER PAGE statements. Covers built-in widget syntax, child slots (TEMPLATE/FILTER), adding new custom widgets via .def.json, and engine internals.
---

# Custom & Pluggable Widgets in MDL

## Built-in Pluggable Widgets

### GALLERY

Card-layout list with optional template content and filters.

```sql
gallery galleryName (
  datasource: database from Module.Entity sort by Name asc,
  selection: single | multiple | none,
  DesktopColumns: 3,
  TabletColumns: 2,
  PhoneColumns: 1
) {
  template template1 {
    dynamictext title (content: '{1}', contentparams: [{1} = Name], rendermode: H4)
    dynamictext info  (content: '{1}', contentparams: [{1} = Email])
  }
  filter filter1 {
    textfilter   searchName  (attribute: Name)
    numberfilter searchScore (attribute: Score)
    dropdownfilter searchStatus (attribute: status)
    datefilter   searchDate  (attribute: CreatedAt)
  }
}
```

- `template` block -> mapped to `content` property (child widgets rendered per row)
- `filter` block -> mapped to `filtersPlaceholder` property (shown above list)
- `selection: none` omits the selection property (default if omitted)
- `DesktopColumns`, `TabletColumns`, `PhoneColumns` control responsive grid columns (default: 1 each, omit if default)
- Children written directly under GALLERY (no container) go to the first slot with `mdlContainer: "template"`

### COMBOBOX

Two modes depending on the attribute type:

```sql
-- Enumeration mode (Attribute is an enum)
combobox cbStatus (label: 'Status', attribute: status)

-- Association mode (Attribute is an association)
combobox cmbCustomer (
  label: 'Customer',
  attribute: Order_Customer,
  datasource: database Module.Customer,
  CaptionAttribute: Name
)
```

- Engine detects association mode when `datasource` is present (`hasDataSource` condition)
- `CaptionAttribute` is the display attribute on the **target** entity
- In association mode, mapping order matters: DataSource must resolve before Association (sets entityContext)

## Charts (Mendix Charts.mpk)

Charts are pluggable widgets authored by their **package id**. Install `Charts.mpk`
into the project's `widgets/` folder first (any Charts-based app has it); `exec`
auto-generates the `.def.json`.

**Chart type → widget id → data container:**

| Chart | Widget id (`pluggablewidget '…'`) | Data block |
|-------|-----------------------------------|------------|
| Bar / Column / Area | `com.mendix.widget.web.{barchart.BarChart, columnchart.ColumnChart, areachart.AreaChart}` | `series` (one or more) |
| Line / TimeSeries / Bubble | `com.mendix.widget.web.{linechart.LineChart, timeseries.TimeSeries, bubblechart.BubbleChart}` | `line` (one or more) |
| HeatMap | `com.mendix.widget.web.heatmap.HeatMap` | widget-level attrs **+** `scalecolor` items |
| Pie | `com.mendix.widget.web.piechart.PieChart` | widget-level attrs (no object-list) |

**Series / line — each binds its OWN datasource + X/Y:**

```
pluggablewidget 'com.mendix.widget.web.barchart.BarChart' chart1 {
  series s1 (
    DataSet: 'static',
    DataSource: database from MyModule.SalesByRegion,  -- an OQL VIEW (aggregated)
    StaticXAttribute: Region,      -- resolves against the series' own datasource
    StaticYAttribute: Total,
    StaticName: 'Revenue',
    Interpolation: 'linear'        -- line/area only: linear | smooth
  )
}
```

**Pie / HeatMap bind at the WIDGET level** (no series block). Both need `DataSource:`
+ `ValueAttribute:`; Pie also needs a required `SeriesName:`; HeatMap adds `scalecolor` items:

```
pluggablewidget 'com.mendix.widget.web.piechart.PieChart' pie1 (
  DataSource: database from MyModule.SalesByRegion,
  ValueAttribute: Total,
  SeriesName: 'Sales by Region'   -- REQUIRED (CE4899 without it)
)

pluggablewidget 'com.mendix.widget.web.heatmap.HeatMap' heat1 (
  DataSource: database from MyModule.SalesByRegion,
  ValueAttribute: Total           -- REQUIRED (CE0642 without it)
) {
  scalecolor scLow  (ValuePercentage: 0,   ColorValue: '#f7fbff')
  scalecolor scHigh (ValuePercentage: 100, ColorValue: '#08306b')
}
```

**Per-chart required-property gotchas (all are mxbuild errors, not `check` errors):**

- **TimeSeries** — `StaticXAttribute` MUST be a **Date and time** attribute (CE7247 otherwise). Feed it a view with a datetime column.
- **BubbleChart** — the `line` needs a `StaticSizeAttribute:` (a numeric) in addition to X/Y.
- **PieChart** — `SeriesName:` is required (CE4899); `ValueAttribute:` is required (CE0642).
- **HeatMap** — `ValueAttribute:` is required (CE0642).

**Data feed = OQL view entities.** Charts want *aggregated* data (one row per
category). Build a `create view entity … as select … group by …` and point the
chart's `DataSource:` at it. **Never name a view column after an OQL keyword**
(`Quarter`/`Month`/`Year`/`Day` → CE0174); use `Period` etc. (`check` warns —
MDL032).

**CE0463 "update this widget" is EXPECTED after generating charts.** mxcli writes
the WidgetType from an embedded 11.6 baseline; the installed Charts.mpk is a
different version, so Studio Pro/mxbuild flags drift. Clear it with **`mxcli docker
check`/`build`** (they normalize the widgets and preserve your storage format). The
whole `mdl-examples/doctype-tests/34-chart-widget-examples.mdl` builds **0 errors**
after normalization.
**Do NOT run bare `mx update-widgets` on an MPRv2 project** (an `mprcontents/`-folder
project — what `mxcli new` creates): it converts the project to single-file v1 and
**deletes `mprcontents/`**, corrupting git, breaking a running `mxcli run --local`
loop, and sometimes making the project unopenable in Studio Pro. `mxcli docker
check`/`build` snapshot/restore the v2 files around the normalization; raw
`mx update-widgets` is only safe on a v1 project or a throwaway diagnostic copy.

**DESCRIBE round-trips** series/line/scalecolor object-lists (item names are
synthesized, e.g. `series1`); a Pie/HeatMap's widget-level `SeriesName`/datasource
are not yet reconstructed.

## Adding a Third-Party Widget

### Step 1 -- Extract .def.json from .mpk

```bash
mxcli widget extract --mpk widgets/MyWidget.mpk
# Output: .mxcli/widgets/mywidget.def.json

# Override MDL keyword
mxcli widget extract --mpk widgets/MyWidget.mpk --mdl-name MYWIDGET
```

The `extract` command parses the .mpk (ZIP archive containing `package.xml` + widget XML) and auto-infers operations from XML property types:

| XML Type | Operation | MDL Source Key |
|----------|-----------|----------------|
| attribute | attribute | `attribute` |
| association | association | `association` |
| datasource | datasource | `datasource` |
| selection | selection | `selection` |
| widgets | widgets (child slot) | container name (key uppercased) |
| boolean/string/enumeration/integer/decimal | primitive | hardcoded `value` from defaultValue |
| action/expression/textTemplate/object/icon/image/file | *skipped* | too complex for auto-mapping |

Skipped types require manual configuration in the .def.json.

### Step 2 -- Extract BSON template from Studio Pro

The .def.json only describes mapping rules. The engine also needs a **template JSON** with the complete Type + Object BSON structure.

```bash
# 1. in Studio Pro: drag the widget onto a test page, save the project
# 2. Extract the widget's BSON:
mxcli bson dump -p App.mpr --type page --object "Module.TestPage" --format json
# 3. Extract the type and object fields from the customwidget, save as:
```

Place at: `project/.mxcli/widgets/mywidget.json`

Template JSON format:

```json
{
  "widgetId": "com.vendor.widget.MyWidget",
  "name": "My widget",
  "version": "1.0.0",
  "extractedFrom": "TestModule.TestPage",
  "type": {
    "$ID": "aa000000000000000000000000000001",
    "$type": "CustomWidgets$CustomWidgetType",
    "WidgetId": "com.vendor.widget.MyWidget",
    "PropertyTypes": [
      {
        "$ID": "aa000000000000000000000000000010",
        "$type": "CustomWidgets$WidgetPropertyType",
        "PropertyKey": "datasource",
        "ValueType": { "$ID": "...", "type": "datasource" }
      }
    ]
  },
  "object": {
    "$ID": "aa000000000000000000000000000100",
    "$type": "CustomWidgets$WidgetObject",
    "TypePointer": "aa000000000000000000000000000001",
    "properties": [
      2,
      {
        "$ID": "...",
        "$type": "CustomWidgets$WidgetProperty",
        "TypePointer": "aa000000000000000000000000000010",
        "value": {
          "$type": "CustomWidgets$WidgetValue",
          "datasource": null,
          "AttributeRef": null,
          "PrimitiveValue": "",
          "widgets": [2],
          "selection": "none"
        }
      }
    ]
  }
}
```

**CRITICAL**: Template must include both `type` (PropertyTypes schema) and `object` (default WidgetObject with all property values). Extract from a real Studio Pro MPR -- do NOT generate programmatically. Mismatched structure causes CE0463.

### Step 3 -- Place files

```
project/.mxcli/widgets/mywidget.def.json   <- project scope (highest priority)
project/.mxcli/widgets/mywidget.json       <- template json (same directory)
~/.mxcli/widgets/mywidget.def.json         <- global scope
```

Set `"templateFile": "mywidget.json"` in the .def.json. Project definitions override global ones; global overrides embedded.

### Step 4 -- Use in MDL

```sql
MYWIDGET myWidget1 (datasource: database Module.Entity, attribute: Name) {
  template content1 {
    dynamictext label1 (content: '{1}', contentparams: [{1}=Name])
  }
}
```

## Authoring over MCP (live Studio Pro)

When mxcli runs with `--mcp` (writes routed to a running Studio Pro), pluggable
widgets take a different, simpler path than the MPR writer:

- **No BSON template needed** -- skip Step 2 entirely. Only the `.def.json`
  (Step 1) is required. Studio Pro owns serialization over `pg_patch_page` and
  expands every default, so the CE0463 template-mismatch class does not exist
  on this path.
- **Any registry-resolved widget is accepted** -- same 3-tier resolution
  (project `.mxcli/widgets/` -> global -> embedded). There is no separate MCP
  whitelist.
- **Supported property operations**: attribute, association, primitive,
  selection, datasource, widgets (child slots), object lists, expression,
  texttemplate (including `{AttrName}` placeholders -> template parameters),
  and action (`microflow Module.Flow`, `show_page Module.Page`, or none).
- **Rejected loudly** (widget refused, nothing sent): actions *with argument
  mappings*, other action kinds (save/cancel/close/delete/create/open-link/
  nanoflow), and any operation the MCP builder does not translate. The error
  names each unsupported property.
- **Selector-primitive pruning gotcha**: Studio Pro prunes properties made
  irrelevant by a mode-selector primitive's default. Example: the Image widget
  drops `imageUrl` unless `ImageType: 'imageUrl'` is also set. If a property
  you set does not appear in Studio Pro, check the widget's mode selector.

## .def.json Reference

```json
{
  "widgetId":        "com.vendor.widget.web.mywidget.MyWidget",
  "mdlName":         "MYWIDGET",
  "templateFile":    "mywidget.json",
  "defaultEditable": "Always",
  "propertyMappings": [
    {"propertyKey": "datasource",  "source": "datasource", "operation": "datasource"},
    {"propertyKey": "attribute",   "source": "attribute",  "operation": "attribute"},
    {"propertyKey": "someFlag",    "value":  "true",       "operation": "primitive"}
  ],
  "childSlots": [
    {"propertyKey": "content", "mdlContainer": "template", "operation": "widgets"}
  ],
  "modes": [
    {
      "name": "association",
      "condition": "hasDataSource",
      "propertyMappings": [
        {"propertyKey": "optionsSource", "value": "association", "operation": "primitive"},
        {"propertyKey": "assocDS",       "source": "datasource",  "operation": "datasource"},
        {"propertyKey": "assoc",         "source": "association", "operation": "association"}
      ]
    },
    {
      "name": "default",
      "propertyMappings": [
        {"propertyKey": "attr", "source": "attribute", "operation": "attribute"}
      ]
    }
  ]
}
```

### Mode Conditions

| Condition | Checks |
|-----------|--------|
| `hasDataSource` | AST widget has a `datasource` property |
| `hasAttribute` | AST widget has an `attribute` property |
| `hasProp:XYZ` | AST widget has a property named `XYZ` |

Modes are evaluated in definition order -- first match wins. A mode with no `condition` is the default fallback.

### 6 Built-in Operations

| Operation | What it does | Typical Source |
|-----------|-------------|----------------|
| `attribute` | Sets `Value.AttributeRef` on a WidgetProperty | `attribute` |
| `association` | Sets `Value.AttributeRef` + `Value.EntityRef` | `association` |
| `primitive` | Sets `Value.PrimitiveValue` | static `value` or property name |
| `datasource` | Sets `Value.DataSource` (serialized BSON) | `datasource` |
| `selection` | Sets `Value.Selection` (mode string) | `selection` |
| `widgets` | Replaces `Value.Widgets` array with child widget BSON | child slot |
| `texttemplate` | Sets text in `Value.TextTemplate` (Forms$ClientTemplate) | property name (resolved as string) |
| `action` | Sets `Value.Action` with serialized client action BSON | `onclick` (resolved from AST Action) |

### Mapping Order Constraints

- **`association` source must come AFTER `datasource` source** in the mappings array. The association operation depends on `entityContext` set by a prior DataSource mapping. The registry validates this at load time.
- **`value` takes priority over `source`**: if both are set, the static `value` is used.

### Source Resolution

| Source | Resolution logic |
|--------|-----------------|
| `attribute` | `w.GetAttribute()` -> `pageBuilder.resolveAttributePath()` |
| `datasource` | `w.GetDataSource()` -> `pageBuilder.buildDataSourceV3()` -> also updates `entityContext` |
| `association` | `w.GetAttribute()` -> `pageBuilder.resolveAssociationPath()` + uses current `entityContext` |
| `selection` | `w.GetSelection()` or `mapping.Default` fallback |
| `CaptionAttribute` | `w.GetStringProp("CaptionAttribute")` -> auto-prefixed with `entityContext` if relative |
| *(other)* | Treated as generic property name: `w.GetStringProp(source)` |

## Engine Internals

### Build Pipeline

When `buildWidgetV3()` encounters an unrecognized widget type:

```
1. Registry lookup: widgetRegistry.Get("MYWIDGET") -> WidgetDefinition
2. template loading: GetTemplateFullBSON(widgetID, idGenerator, projectPath)
   a. Load json from embed.FS (or .mxcli/widgets/)
   b. Augment from project's .mpk (if newer version available)
   c. Phase 1: Collect all $ID values -> generate new UUID mapping
   d. Phase 2: Convert type json -> BSON, extract PropertyTypeIDMap
   e. Phase 3: Convert object json -> BSON (TypePointer remapped via same mapping)
   f. placeholder leak check (aa000000-prefix IDs must all be remapped)
3. Mode selection: evaluateCondition() on each mode in order -> first match wins
4. Property mappings: for each mapping, resolveMapping() -> OperationFunc()
   Each operation locates the WidgetProperty by matching TypePointer against PropertyTypeIDMap
5. Child slots: group AST children by container name, build to BSON, embed via opWidgets
6. Assemble customwidget{RawType, RawObject, PropertyTypeIDMap, ObjectTypeID}
```

### PropertyTypeIDMap

The map links PropertyKey names (from .def.json) to their BSON IDs:

```
PropertyTypeIDMap["datasource"] = {
  PropertyTypeID: "a1b2c3d4...",   // $ID of WidgetPropertyType in type
  ValueTypeID:    "e5f6a7b8...",   // $ID of ValueType within PropertyType
  DefaultValue:   "",
  ValueType:      "datasource",    // type string
  ObjectTypeID:   "...",           // for nested object list properties
}
```

Operations use this map to locate the correct WidgetProperty in the Object's Properties array by comparing `TypePointer` (binary GUID) against `PropertyTypeID`.

### MPK Augmentation

At template load time, `augmentFromMPK()` checks if the project has a newer `.mpk` for the widget:

```
project/widgets/*.mpk -> FindMPK(projectDir, widgetID) -> ParseMPK()
-> AugmentTemplate(clone, mpkDef)
   -> add missing properties from newer .mpk version
   -> remove stale properties no longer in .mpk
```

This reduces CE0463 errors from widget version drift without requiring manual template re-extraction.

### 3-Tier Registry

| Priority | Location | Scope |
|----------|----------|-------|
| 1 (highest) | `<project>/.mxcli/widgets/*.def.json` | Project |
| 2 | `~/.mxcli/widgets/*.def.json` | Global (user) |
| 3 (lowest) | `sdk/widgets/definitions/*.def.json` (embedded) | Built-in |

Higher priority definitions override lower ones with the same MDL name (case-insensitive).

## Verify & Debug

```bash
# list registered widgets
mxcli widget list -p App.mpr

# check after creating a page
mxcli check script.mdl -p App.mpr --references

# full mx check (catches CE0463)
~/.mxcli/mxbuild/*/modeler/mx check App.mpr

# debug CE0463 -- compare NDSL dumps
mxcli bson dump -p App.mpr --type page --object "Module.PageName" --format ndsl
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| CE0463 after page creation | Template version mismatch -- extract fresh template from Studio Pro MPR, or ensure .mpk augmentation picks up new properties |
| Widget not recognized | Check `mxcli widget list`; .def.json must be in `.mxcli/widgets/` with `.def.json` extension |
| TEMPLATE content missing | Widget needs `childSlots` entry with `"mdlContainer": "template"` |
| Association COMBOBOX shows enum behavior | Add `datasource` to trigger association mode (`hasDataSource` condition) |
| Association mapping fails | Ensure DataSource mapping appears **before** Association mapping in the array |
| Custom widget not found | Place .def.json in `.mxcli/widgets/` inside the project directory |
| Placeholder ID leak error | Template JSON has unreferenced `$ID` values starting with `aa000000` -- ensure all IDs are in the `collectIDs` traversal path |

## Key Source Files

| File | Purpose |
|------|---------|
| `mdl/executor/widget_engine.go` | PluggableWidgetEngine, 6 operations, Build() pipeline |
| `mdl/executor/widget_registry.go` | 3-tier WidgetRegistry, definition validation |
| `sdk/widgets/loader.go` | Template loading, ID remapping, MPK augmentation |
| `sdk/widgets/mpk/mpk.go` | .mpk ZIP parsing, XML property extraction |
| `cmd/mxcli/cmd_widget.go` | `mxcli widget extract/list` CLI commands |
| `sdk/widgets/definitions/*.def.json` | Built-in widget definitions (ComboBox, Gallery) |
| `sdk/widgets/templates/mendix-11.6/*.json` | Embedded BSON templates |
| `mdl/executor/cmd_pages_builder_input.go` | `updateWidgetPropertyValue()` -- TypePointer matching |
