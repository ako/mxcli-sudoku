# ALTER PAGE / ALTER SNIPPET - Modify Existing Pages and Snippets

## Overview

ALTER PAGE and ALTER SNIPPET modify an existing page or snippet's widget tree **in-place** without requiring a full `create or replace`. Operations work directly on the raw BSON tree, preserving widget types and properties that MDL doesn't explicitly model.

## When to Use

| Scenario | Use |
|----------|-----|
| Change a button caption, label, or style | `alter page` with `set` |
| Add a field to an existing form | `alter page` with `insert` |
| Remove unused widgets | `alter page` with `drop` |
| Replace a footer or section | `alter page` with `replace` |
| Several related changes on the same page | `alter page` with multiple operations in one block |
| Same property across many pages (e.g., add `Class` to every Container) | `update widgets` — see `bulk-widget-updates.md` |
| Rebuild entire page from scratch | `create or replace page` |
| Create a new page | `create page` |

**Rule of thumb:**
- `alter page` — targeted edits to one page. Combine multiple ops in one block when they belong together.
- `update widgets` — cross-page bulk updates with `WHERE` filtering and `DRY RUN`.
- `create or replace page` — redefining the full page structure.

## Syntax

```sql
alter page Module.PageName {
  operation1;
  operation2;
  ...
};

alter snippet Module.SnippetName {
  operation1;
  operation2;
  ...
};
```

Multiple operations can be combined in a single ALTER statement. They are applied sequentially; later operations see the page state produced by earlier ones, so you can `set` on a widget you just `insert`ed.

```sql
-- Rename a column, add a sibling, drop an obsolete one — all in one block.
alter page MyMod.Product_Overview {
  set caption = 'Product Name' on dgProducts.Name;
  insert after dgProducts.Lifecycle {
    column NewCol (attribute: Sku, caption: 'SKU')
  };
  drop widget dgProducts.OldCol
};
```

For changes that should be applied across **many pages** (e.g., "add `Class='card'` to every Container in `MyMod`"), use `UPDATE WIDGETS` instead — see `bulk-widget-updates.md`.

## Operations

### SET - Modify Widget Properties

```sql
-- Single property
set caption = 'New Caption' on widgetName

-- Multiple properties
set (caption = 'Save & Close', buttonstyle = success) on btnSave

-- Page-level property (no ON clause). Page-level property names are
-- case-sensitive and must match the Mendix property exactly.
set Title = 'New Page Title'

-- Pop-up dimensions (apply when the page is opened in a pop-up)
set PopupWidth = 800
set PopupHeight = 480
set PopupResizable = true
```

**Supported SET properties:**

| Property | Widget Types | Value Type | Example |
|----------|-------------|------------|---------|
| `caption` | ACTIONBUTTON, LINKBUTTON | String | `set caption = 'Submit' on btnSave` |
| `content` | DYNAMICTEXT | String | `set content = 'New Heading' on txtTitle` |
| `label` | TEXTBOX, TEXTAREA, DATEPICKER, COMBOBOX, CHECKBOX, RADIOBUTTONS | String | `set label = 'full Name' on txtName` |
| `buttonstyle` | ACTIONBUTTON, LINKBUTTON | Primary, Default, Success, Danger, Warning, Info | `set buttonstyle = danger on btnDelete` |
| `class` | Any widget | CSS class string | `set class = 'card mx-2' on container1` |
| `style` | Any widget (see warning below) | Inline CSS string | `set style = 'padding: 16px;' on container1` |
| `editable` | Input widgets | String | `set editable = 'Never' on txtReadOnly` |
| `visible` | Any widget | String or Boolean | `set visible = false on txtHidden` |
| `Name` | Any widget | String | `set Name = 'newName' on oldName` |
| `Title` | Page-level only (case-sensitive) | String | `set Title = 'Edit Customer'` |
| `layout` | Page-level only | Qualified name | `set layout = Atlas_Core.Atlas_Default` |
| `PopupWidth` | Page-level only (case-sensitive) | Positive integer (pixels) | `set PopupWidth = 800` |
| `PopupHeight` | Page-level only (case-sensitive) | Positive integer (pixels) | `set PopupHeight = 480` |
| `PopupResizable` | Page-level only (case-sensitive) | Boolean | `set PopupResizable = true` |
| `Class` | Page-level (case-sensitive, no ON) | CSS class string | `set Class = 'container-fluid bg-light'` |
| `Style` | Page-level (case-sensitive, no ON) | Inline CSS string | `set Style = 'min-height: 100vh'` |
| `Visible` (conditional) | Any widget | `[expression]` | `set Visible = [Name != ''] on ctnDetails` |
| `Editable` (conditional) | Input widgets | `[expression]` | `set Editable = [Active] on txtName` |
| `'quotedProp'` | Pluggable widgets | String, Boolean, Number | `set 'showLabel' = false on cbStatus` |

> **Conditional visibility/editability** — `set Visible = [expr] on widget` (and
> `Editable`) attach a per-object expression. Bare attributes are rooted in the
> widget data context automatically: `[Name != '']` becomes
> `$currentObject/Name != ''` (paths you write with `$currentObject/…`/`$Param/…`
> pass through). Setting `Editable` on a non-input widget is rejected. This mirrors
> CREATE PAGE's `visible: [...]` — see the create-page skill for enum-value rules.

**Pluggable widget properties** use quoted names to set values in the widget's `Object.Properties[]`. Boolean values are stored as `"yes"`/`"no"` in BSON.

**Column property names are case-insensitive** in MDL — `set caption = …` and `set Caption = …` both work. The internal BSON keys are dictated by the widget schema and stay case-sensitive on the storage side.

> **Warning: Style on DYNAMICTEXT** — Setting `style` directly on a DYNAMICTEXT widget crashes MxBuild with a NullReferenceException. Wrap the DYNAMICTEXT in a CONTAINER and apply styling to the container instead:
> ```sql
> -- Wrong: crashes MxBuild
> SET Style = 'color: red;' ON txtHeading
>
> -- Correct: style the container
> REPLACE txtHeading WITH {
>   CONTAINER ctnHeading (Style: 'color: red;') {
>     DYNAMICTEXT txtHeading (Content: 'Heading', RenderMode: H2)
>   }
> }
> ```

### INSERT - Add Widgets

```sql
-- Insert after a widget
insert after txtName {
  textbox txtMiddleName (label: 'Middle Name', attribute: MiddleName)
}

-- Insert before a widget
insert before btnSave {
  actionbutton btnPreview (caption: 'Preview', action: microflow Module.ACT_Preview)
}

-- Insert INTO a container — append as its last child (works on an EMPTY container)
insert into ctnToolbar {
  actionbutton btnNew (caption: 'New', action: nothing, buttonstyle: primary)
}
```

Inserted widgets use the same syntax as `create page`. Multiple widgets can be inserted in a single block.

`insert into <container>` appends as the last child of the named container — the
only way to fill an **empty** container, and handy for adding to a container/dataview
without needing a sibling to anchor to. Widgets inserted into a dataview take that
dataview's entity as their context. Supported on simple containers (container,
dataview, groupbox, scroll-container region); for a layout grid or tab container,
insert relative to a widget inside the target column/tab instead.

### DROP - Remove Widgets

```sql
-- Drop a single widget
drop widget txtUnused

-- Drop multiple widgets
drop widget txtOldField, lblOldLabel, container2
```

Removes widgets and their entire subtree from the page.

### REPLACE - Replace Widget Subtree

```sql
-- Replace a single widget with new content
replace footer1 with {
  footer newFooter {
    actionbutton btnSave (caption: 'Save', action: save_changes, buttonstyle: primary)
    actionbutton btnCancel (caption: 'Cancel', action: cancel_changes)
  }
}
```

Replaces the target widget with one or more new widgets. The new widgets use the same syntax as `create page`.

### DataGrid Column Operations

DataGrid2 columns are addressable using dotted notation: `gridName.columnName`. The column name is derived from the attribute short name or caption (same as shown by `describe page`).

```sql
-- SET a column property
set caption = 'Product SKU' on dgProducts.Code

-- DROP a column
drop widget dgProducts.OldColumn

-- INSERT a column after an existing one
insert after dgProducts.Price {
  column Margin (attribute: Margin, caption: 'Margin')
}

-- REPLACE a column
replace dgProducts.Description with {
  column Notes (attribute: Notes, caption: 'Notes')
}
```

To discover column names, run `describe page Module.PageName` and look at the COLUMN names inside the DATAGRID.

**Troubleshooting: column operation succeeds but does nothing**
If an ALTER targeting a DataGrid column completes without error but makes no change, the column name used in the statement didn't match any column. The most common cause is a mismatch between what DESCRIBE shows and what ALTER resolves internally. Derivation rules:
- Attribute-bound column → short attribute name (last segment after `.`): `Module.Entity.Description` → `Description`
- Caption-only column → sanitized caption (non-alphanumeric replaced with `_`, leading/trailing `_` trimmed): `"Order Status"` → `Order_Status`
- Caption with only special chars (e.g. `"---"`) → falls back to `col1`, `col2`, … (1-based index)

If the column name you copied from DESCRIBE still doesn't work, check whether the column has an attribute binding — attribute names take priority over captions.

### ADD Variables - Add a Page Variable

```sql
add variables $showStockColumn: boolean = 'true'
```

Adds a new page variable (`Forms$LocalVariable`) to the page/snippet. DataType can be `boolean`, `string`, `integer`, `decimal`, `datetime`, or an entity type. Default value is a Mendix expression in single quotes.

### DROP Variables - Remove a Page Variable

```sql
drop variables $showStockColumn
```

Removes a page variable by name.

### SET Layout - Change Page Layout

```sql
-- Auto-map placeholders by name (most common case)
set layout = Atlas_Core.Atlas_Default

-- Explicit mapping when placeholder names differ
set layout = Atlas_Core.Atlas_SideBar map (Main as content, Extra as Sidebar)
```

Changes the page's layout without rebuilding the widget tree. Only rewrites the `FormCall.Form` and `FormCall.Arguments[].Parameter` BSON fields — all widget content is preserved. Not supported for snippets.

When placeholders have the same names in both layouts (e.g., both have `Main`), auto-mapping works. Use `map` when placeholder names differ between the old and new layout.

## Examples

### Change button text and style

```sql
alter page MyModule.Customer_Edit {
  set (caption = 'Save & Close', buttonstyle = success) on btnSave
};
```

### Add a field to a form

```sql
alter page MyModule.Customer_Edit {
  insert after txtEmail {
    textbox txtPhone (label: 'Phone', attribute: Phone)
  }
};
```

### Add a page variable for column visibility

```sql
alter page MyModule.ProductOverview {
  add variables $showStockColumn: boolean = 'if (3 < 4) then true else false'
};
```

### Remove unused fields and update title

```sql
alter page MyModule.Customer_Edit {
  set title = 'Edit Customer Details';
  drop widget txtLegacyField, lblOldNote;
  set label = 'Email Address' on txtEmail
};
```

### Replace a footer section

```sql
alter page MyModule.Customer_Edit {
  replace footer1 with {
    footer newFooter {
      actionbutton btnSave (caption: 'Save', action: save_changes, buttonstyle: success)
      actionbutton btnDelete (caption: 'Delete', action: delete, buttonstyle: danger)
      actionbutton btnCancel (caption: 'Cancel', action: cancel_changes)
    }
  }
};
```

### Modify a snippet

```sql
alter snippet MyModule.NavigationMenu {
  set caption = 'Dashboard' on btnHome;
  insert after btnHome {
    actionbutton btnReports (caption: 'Reports', action: show_page MyModule.Reports_Overview)
  }
};
```

### Set pluggable widget properties

```sql
alter page MyModule.Customer_Edit {
  set 'showLabel' = false on cbStatus;
  set 'labelWidth' = 4 on cbCategory
};
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Missing `on widgetName` for widget SET | Add `on widgetName` (only page-level properties — `Title`, `PopupWidth`, `PopupHeight`, `PopupResizable`, `Class`, `Style` — omit ON) |
| `unsupported page-level property: title` | Page-level property names are case-sensitive — use `Title`, `PopupWidth`, `PopupHeight`, `PopupResizable`, `Class`, `Style` |
| Using unquoted pluggable property names | Quote pluggable props: `set 'showLabel' = false on cb` |
| Wrong widget name | Use `describe page Module.Name` to see widget names |
| SET on non-existent widget | Widget names are case-sensitive; check with DESCRIBE |
| Missing semicolons between operations | Each operation inside `{ }` ends with `;` |

## Validation Checklist

1. **Get widget names first**: Run `describe page Module.PageName` to see all widget names
2. **Check syntax**: `mxcli check script.mdl`
3. **Check references**: `mxcli check script.mdl -p app.mpr --references`
4. **Verify result**: Run `describe page Module.PageName` after ALTER to confirm changes
5. **Validate project**: `~/.mxcli/mxbuild/*/modeler/mx check app.mpr` (or `mxcli docker check -p app.mpr`)

## Related Commands

- `describe page Module.PageName` - View current page structure (get widget names)
- `describe snippet Module.SnippetName` - View current snippet structure
- `create [or replace] page` - Create or fully rebuild a page
- `create [or replace] snippet` - Create or fully rebuild a snippet
- `update widgets set ... where ...` - Bulk update widget properties across pages
- `drop page Module.PageName` - Delete a page
- `drop snippet Module.SnippetName` - Delete a snippet

## Related Skills

- [Create Page](./create-page.md) - Full page creation syntax
- [Overview Pages](./overview-pages.md) - CRUD page patterns
- [Master-Detail Pages](./master-detail-pages.md) - Selection binding pattern
