# Resolving Forward References in MDL Scripts

## Why Forward References Fail

MDL script execution is **sequential and immediate** — each `CREATE` statement commits
its document to the project database before the next statement runs. When a document is
being built, all its references (snippets, pages, microflows) are resolved against the
database at that moment. A reference to something defined *later in the same script* fails
because it is not in the database yet.

```
Error: snippet not found: MyModule.NavMenu
```

This applies to the following reference types:

| Reference | In | Fails when |
|---|---|---|
| `snippetcall` | page / snippet | snippet created after the page |
| `show_page` in action | page / snippet | page created after the page that references it |
| `SHOW PAGE` | microflow | page created after the microflow |
| `call microflow` | microflow | already works — microflow resolver checks in-session cache |

> **Note:** `SHOW PAGE` inside a microflow body resolves the page reference at
> microflow-creation time, not at invocation time. If the target page doesn't exist yet,
> the microflow creation fails.

---

## The Placeholder Pattern

The standard workaround is a three-step sequence:

1. **Create a minimal placeholder** for the document that will be referenced.
2. **Create all documents that reference it.** They bind to the placeholder's ID.
3. **Fill in the placeholder** using `CREATE OR MODIFY` or `ALTER` — both preserve the
   original ID so existing bindings remain valid.

> **Critical:** Never use `CREATE OR REPLACE` for the fill-in step. `OR REPLACE` deletes
> the placeholder and creates a new document with a different ID. Every page or snippet
> that references the placeholder immediately becomes a dangling reference.

---

## Pattern 1 — Shared Navigation Snippet (most common)

A navigation snippet contains `show_page` buttons (references pages) and pages include
the snippet via `snippetcall` (references the snippet). Both sides reference each other.

```sql
-- Step 1: placeholder snippet (minimal valid content)
create snippet MyModule.NavMenu
(
  layout: Atlas_Core.Atlas_Default
)
{
  layoutgrid g { row r { column c (desktopwidth: 12) {
    dynamictext loading (content: 'Loading...')
  }}}
}
/

-- Step 2: pages that embed the snippet (snippet already exists → resolves OK)
create page MyModule.Customer_Overview
(
  title: 'Customers',
  layout: Atlas_Core.Atlas_Default
)
{
  layoutgrid g { row r {
    column c1 (desktopwidth: 3) {
      snippetcall nav (snippet: MyModule.NavMenu)
    }
    column c2 (desktopwidth: 9) {
      datagrid dg (datasource: database MyModule.Customer) { }
    }
  }}
}
/

create page MyModule.Order_Overview
(
  title: 'Orders',
  layout: Atlas_Core.Atlas_Default
)
{
  layoutgrid g { row r {
    column c1 (desktopwidth: 3) {
      snippetcall nav (snippet: MyModule.NavMenu)
    }
    column c2 (desktopwidth: 9) {
      datagrid dg (datasource: database MyModule.Order) { }
    }
  }}
}
/

-- Step 3: fill in the snippet with real content (pages now exist → show_page resolves OK)
-- Use CREATE OR MODIFY (preserves ID) or ALTER SNIPPET (in-place)
create or modify snippet MyModule.NavMenu
(
  layout: Atlas_Core.Atlas_Default
)
{
  layoutgrid g { row r { column c (desktopwidth: 12) {
    actionbutton btnCustomers (
      caption: 'Customers',
      action: show_page MyModule.Customer_Overview
    )
    actionbutton btnOrders (
      caption: 'Orders',
      action: show_page MyModule.Order_Overview
    )
  }}}
}
/
```

---

## Pattern 2 — Page References Another Page (new/edit from overview)

An overview page has a New button that opens a NewEdit page via `show_page`. The NewEdit
page must exist before the overview can reference it.

```sql
-- Solution: declare the target page first (even if empty), then the referencing page

create page MyModule.Customer_NewEdit
(
  params: { $Customer: MyModule.Customer },
  title: 'Edit Customer',
  layout: Atlas_Core.PopupLayout
)
{
  layoutgrid g { row r { column c (desktopwidth: 12) {
    dataview dv (datasource: $Customer) {
      textbox txtName (label: 'Name', attribute: Name)
    }
    actionbutton btnSave (caption: 'Save', action: save_changes)
    actionbutton btnCancel (caption: 'Cancel', action: cancel_changes)
  }}}
}
/

-- Now the overview can safely reference the NewEdit page
create page MyModule.Customer_Overview
(
  title: 'Customers',
  layout: Atlas_Core.Atlas_Default
)
{
  layoutgrid g { row r { column c (desktopwidth: 12) {
    actionbutton btnNew (
      caption: 'New',
      action: microflow MyModule.ACT_Customer_New
    )
    datagrid dg (datasource: database MyModule.Customer) {
      column colName (caption: 'Name', attribute: Name)
    }
  }}}
}
/
```

For simple cases, reordering declarations is sufficient and no placeholder is needed.

---

## Pattern 3 — Microflow References a Page Not Yet Created

```sql
-- If the page is defined later in the script, create a placeholder or reorder.
-- Easiest fix: declare the page before the microflow that shows it.

-- Page first
create page MyModule.Order_Detail
(
  params: { $Order: MyModule.Order },
  title: 'Order Detail',
  layout: Atlas_Core.Atlas_Default
)
{
  layoutgrid g { row r { column c (desktopwidth: 12) {
    dataview dv (datasource: $Order) {
      textbox txtID (label: 'Order ID', attribute: OrderID)
    }
  }}}
}
/

-- Microflow after the page it references
create microflow MyModule.ACT_OpenOrder ($Order: MyModule.Order)
begin
  @position(200,200)
  show page MyModule.Order_Detail ($Order = $Order);
  @position(400,200) return;
end;
/
```

---

## Ordering Rules for Dependency-Free Scripts

To avoid forward references entirely, follow this declaration order within a script:

```
1. Entities and associations       (no cross-document references)
2. Enumerations and constants      (no cross-document references)
3. Snippets (placeholder if needed)
4. Pages                           (reference snippets + other pages)
5. Snippets (fill-in step, if placeholder was used)
6. Microflows and nanoflows        (reference pages, entities)
7. Navigation                      (references pages)
```

When generating MDL scripts, write sections in this order. Doing so avoids the placeholder
pattern for the majority of scripts.

---

## Choosing Between CREATE OR MODIFY and ALTER SNIPPET

Both preserve the snippet's ID. Use whichever fits:

| Approach | When to use |
|---|---|
| `create or modify snippet` | Rewriting the whole snippet body from scratch |
| `alter snippet` | Inserting or replacing specific widgets within an existing layout |

```sql
-- ALTER SNIPPET: targeted widget replacement (keeps surrounding structure)
alter snippet MyModule.NavMenu
  replace activity loading
  with actionbutton btnCustomers (
    caption: 'Customers',
    action: show_page MyModule.Customer_Overview
  );
```

---

## Script Template for a Full CRUD Module

```sql
-- ============================================================
-- MyModule CRUD scaffold
-- Correct declaration order: snippets → pages → microflows → nav
-- ============================================================

-- 1. Placeholder for shared navigation (will reference pages created below)
create snippet MyModule.AppNav
(layout: Atlas_Core.Atlas_Default)
{
  layoutgrid g { row r { column c (desktopwidth: 12) {
    dynamictext placeholder (content: '...')
  }}}
}
/

-- 2. NewEdit page (referenced by Overview's New button)
create page MyModule.Customer_NewEdit
(
  params: { $Customer: MyModule.Customer },
  title: 'Edit Customer',
  layout: Atlas_Core.PopupLayout
)
{
  -- ... widgets ...
}
/

-- 3. Overview page (references NewEdit + NavMenu)
create page MyModule.Customer_Overview
(
  title: 'Customers',
  layout: Atlas_Core.Atlas_Default
)
{
  layoutgrid g { row r {
    column c1 (desktopwidth: 3) {
      snippetcall nav (snippet: MyModule.AppNav)
    }
    column c2 (desktopwidth: 9) {
      -- ... datagrid with New button calling ACT_Customer_New ...
    }
  }}
}
/

-- 4. Fill in navigation (pages now exist)
create or modify snippet MyModule.AppNav
(layout: Atlas_Core.Atlas_Default)
{
  layoutgrid g { row r { column c (desktopwidth: 12) {
    actionbutton btnCustomers (
      caption: 'Customers',
      action: show_page MyModule.Customer_Overview
    )
  }}}
}
/

-- 5. Microflows (pages already exist)
create microflow MyModule.ACT_Customer_New ()
begin
  @position(200,200)
  $c = create MyModule.Customer;
  @position(400,200)
  show page MyModule.Customer_NewEdit ($Customer = $c);
  @position(600,200) return;
end;
/

-- 6. Navigation (pages already exist)
alter navigation Responsive
  insert menu item 'Customers'
    action show_page MyModule.Customer_Overview;
```

---

## Related Skills

- [Create Page](./create-page.md) — Full page syntax reference
- [Overview Pages](./overview-pages.md) — Overview + NewEdit page patterns
- [ALTER PAGE/SNIPPET](./alter-page.md) — In-place snippet modification
