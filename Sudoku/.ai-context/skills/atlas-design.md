# Atlas Design — Make a Mendix App Look Designed, Not Bland

## When to Use This Skill

Use this skill when:
- The user asks to make an app "look good / professional / branded / less bland"
- You are about to style a Mendix web app or a group of pages
- You are matching a design mock and want it to reach "designed product" quality
- You are re-branding an existing app to a new identity (palette, type, corners)

This is the **taste + workflow** layer. It sits on top of the styling mechanics
(`theme-styling.md`), the widget syntax (`create-page.md`), the composition
primitives (`fragments.md`), and the design-handoff pipeline
(`migrate-design-prototype.md`). It does **not** re-teach SCSS compilation or
`Class:`/`DesignProperties:` syntax — those skills own that. It adds **which**
tokens/classes to use, **when**, and the **discover → inspect → use** method
built on the Atlas building blocks every Mendix project already ships.

## Contents

1. [The thesis: be Atlas-first](#the-thesis-be-atlas-first)
2. [The 4-layer architecture](#the-4-layer-architecture)
3. [The workflow: discover → inspect → use](#the-workflow-discover--inspect--use)
4. [Atlas building blocks — the out-of-the-box inventory](#atlas-building-blocks--the-out-of-the-box-inventory)
5. [Atlas appearance vocabulary — classes & design properties](#atlas-appearance-vocabulary--classes--design-properties)
6. [Brand re-tune (Layer 1) — where most of the win is](#brand-re-tune-layer-1--where-most-of-the-win-is)
7. [Layer-1 brand scaffold — copy into theme/web/custom-variables.scss](#layer-1-brand-scaffold--copy-into-themewebcustom-variablesscss)
8. [Charts — a dataviz-grade theme for the Mendix chart widgets](#charts--a-dataviz-grade-theme-for-the-mendix-chart-widgets)
9. [Dark mode — commit to one theme](#dark-mode--commit-to-one-theme)
10. [Optional dark-mode Atlas-widget overrides](#optional-dark-mode-atlas-widget-overrides)
11. [Verify at runtime — this is mandatory](#verify-at-runtime--this-is-mandatory)
12. [Gotchas catalog](#gotchas-catalog)
13. [Validation checklist](#validation-checklist)
14. [Related skills](#related-skills)

---

## The thesis: be Atlas-first

Every Mendix project ships **Atlas** — a rich appearance system (`Atlas_Core`
classes + typed design properties) and **39 out-of-the-box building blocks**
(`Atlas_Web_Content`: cards, headers, forms, lists, timelines, wizards, alerts).
The single biggest mistake is hand-rolling `.panel` / `.trip-card` / `.stat`
SCSS that **reinvents what Atlas already gives you for free**.

Live testing proved the point: a page of **pure Atlas classes, zero custom CSS**
renders real cards, brand-coloured backgrounds and buttons, and flex layouts —
and those Atlas utilities **inherit your retuned brand tokens automatically**
(`background-primary` resolves to *your* `--brand-primary`).

**Reach *down* the stack first.** Need a card? `class:'card'` (or `'Card style': on`)
before writing a `.panel` rule. Brand blue on a button? Retune `--brand-primary`
before overriding `.btn-primary`. Custom CSS is the **last** resort — for identity
only (a mono metric type, a timeline spine, a bespoke elevation curve).

---

## The 4-layer architecture

Style from the bottom up. Each layer only does what the layer below can't.

```
Layer 3  VERIFY      run --local --watch  +  Playwright screenshot   (mx check is NOT enough)
Layer 2  IDENTITY    themesource/<mod>/web/main.scss — custom tokens + recipe classes
                     (mono type, status pills, timeline spine) — ONLY what Atlas can't provide
Layer 1  BRAND       theme/web/custom-variables.scss — retune Atlas tokens (--brand-primary,
                     backgrounds, semantic colors, radius) so Atlas components inherit the palette
Layer 0  ATLAS       Atlas classes / design properties / building blocks — structure & base look
```

- **Layer 0 — Atlas.** Compose with the Atlas vocabulary (the class cheat-sheet and
  the building-block inventory below).
- **Layer 1 — Brand.** Retune Atlas tokens in `theme/web/custom-variables.scss` so
  the whole framework (buttons, backgrounds, form inputs, pluggable widgets like
  Switch/Slider/ProgressBar) picks up your palette. Scaffold below.
- **Layer 2 — Identity.** Only the handful of shapes Atlas genuinely can't express
  go in `main.scss` as prefixed recipe classes. See `theme-styling.md` for the SCSS
  chain and `migrate-design-prototype.md` for the token→component method.
- **Layer 3 — Verify.** Non-negotiable. `mx check` misses client-side crashes; you
  must screenshot a *running* build.

A Layer-1 token retune **cascades down** into Atlas components and pluggable
widgets for free — that is the headline payoff. A full re-brand (new palette, type,
corners) is **theme-only**: retune `custom-variables.scss` + `main.scss`, zero
page/MDL edits, and it hot-applies under `--watch`.

---

## The workflow: discover → inspect → use

Building blocks are the Mendix-native recipe library. mxcli can **read and
instantiate** them, so the workflow is:

**1. Discover what your project ships.**
```bash
mxcli -p app.mpr -c "show building blocks"
mxcli -p app.mpr -c "show building blocks in Atlas_Web_Content"
mxcli -p app.mpr -c "select QualifiedName, Category from CATALOG.building_blocks"
```

**2. Inspect the block you want to reproduce.** `describe` prints its real widget
tree — the exact classes and typed design properties Mendix itself uses:
```bash
mxcli -p app.mpr -c "describe building block Atlas_Web_Content.Card"
```
```
{
  container container2 (DesignProperties: ['Card style': on]) {
    dynamictext text22 (Content: 'Card title', RenderMode: H4, Class: 'card-title',
      DesignProperties: ['Spacing': ['margin-bottom': 'L']])
  }
}
```
Note the **two styling channels** Atlas uses side by side: the `Class:` vocabulary
(`card-title`) *and* typed `DesignProperties:` (`'Card style': on`, `Spacing`).

**3. Use it — one line.** `use building block` deep-copies the block's widget tree
onto your page, exactly like dragging it in from the Studio Pro toolbox. Add
`as <prefix>` to rename the copied widgets (so you can drop the same block in twice):

```mdl
use building block Atlas_Web_Content.Card as cust_
```

That expands to the exact tree `DESCRIBE` showed — here `cust_container2` +
`cust_text22`, carrying the `card-title` class and the `Card style` design property.
It's a page-body element: put it inside a `create page` / `alter page` container,
anywhere a widget or `use fragment` can go.

**4. Configure the copy afterwards.** A building block has no parameters — it's a raw
widget-tree template — so you bind data / set text by editing the *copied* widgets
with `alter page` (their names are deterministic thanks to the prefix):

```mdl
alter page Sales.CustomerOverview set cust_text22 (content: 'Customers');
```

> **Capability reality.** Discovery (`SHOW`/`DESCRIBE BUILDING BLOCK`,
> `CATALOG.building_blocks`) **and** instantiation (`USE BUILDING BLOCK`) both work
> today. `use building block` v1 is **deep-copy + optional `as <prefix>`**; configure
> the copy afterwards with `alter page` (an inline override block is a proposed v1.1).
> It runs on `MXCLI_ENGINE=legacy` today; modelsdk-engine support lands with that
> engine's `ListBuildingBlocks`.

**When to *mirror* instead.** *Mirroring* — reproducing a block's tree by hand with
`create page`/`alter page` + the same classes and design properties (see below) — is
the fallback: reach for it only to hand-tune a shape Atlas doesn't quite give you, or
on the modelsdk engine before its building-block support lands. Otherwise prefer the
one-line `use building block`.

---

## Atlas building blocks — the out-of-the-box inventory

Every Mendix project ships **`Atlas_Web_Content`**, a library of **39 building
blocks**: pre-composed widget shapes that Mendix itself uses. They are the canonical
reference for "what a well-made X looks like in Atlas."

### The inventory (real names, grouped by category)

| Category | Blocks |
|---|---|
| **Cards** | `Card`, `Card_Action`, `Card_ActionWithImage`, `Card_Background`, `Card_WithImage` |
| **Headers** | `Heroheader`, `Heroheader_Background`, `Heroheader_WithAction`, `Pageheader`, `Pageheader_WithBack`, `Pageheader_WithControls`, `Pageheader_WithSearch`, `PageheaderImage`, `PageheaderImage_WithBack`, `PageheaderImage_WithControls` |
| **Forms** | `Form_Horizontal`, `Form_Horizontal_WithTitle`, `Form_Horizontal_WithAction`, `Form_Vertical`, `Form_Vertical_WithTitle`, `Form_Vertical_WithAction` |
| **Lists** | `List_Cards`, `List_WithImage`, `ListItem_SingleLine`, `ListItem_DoubleLine`, `ListItem_WithImage` |
| **Master Detail** | `Master_Detail` |
| **Timeline** | `Timeline`, `Timeline_WithImage` |
| **Wizards** | `Wizard_Arrow`, `Wizard_Arrow_Step`, `Wizard_Circle`, `Wizard_Circle_Step` |
| **Notifications** | `Alert`, `Alert_WithAction`, `AlertIcon`, `AlertIcon_WithAction` |
| **Breadcrumbs** | `Breadcrumb`, `Breadcrumb_Underline` |

All are `Platform: Web`, all live in module `Atlas_Web_Content`, referenced as
`Atlas_Web_Content.<Name>`.

> Your project may ship more blocks from installed modules (e.g. a feedback widget).
> Always `show building blocks` on the actual project rather than trusting this list —
> it is the standard Atlas baseline, not an exhaustive per-project inventory.

### Capability reality: discover, inspect, and instantiate

| Capability | State |
|---|---|
| **Discover** — `SHOW BUILDING BLOCKS`, `CATALOG.building_blocks` | ✅ shipped |
| **Inspect** — `DESCRIBE BUILDING BLOCK Mod.Name` (full widget tree) | ✅ shipped |
| **Instantiate** — `use building block Mod.Name [as prefix_]` onto a page | ✅ v1 (deep-copy; configure afterwards with `alter page`; legacy engine today) |
| **Author** — `CREATE BUILDING BLOCK` | ❌ not yet (proposed) |

The one-line `use building block` (above) is the normal path — deep-copy the block,
then configure the copy. **Mirroring** — reproducing a block's widget tree by hand —
is the fallback for hand-tuning or the modelsdk engine; the how-to is below.

### How to mirror a block

1. **Inspect it.** `describe building block Atlas_Web_Content.<Name>`.
2. **Read both channels.** Atlas blocks style with `Class:` strings *and* typed
   `DesignProperties:` — copy both.
3. **Reproduce the tree** on your page, binding real data where the block has
   placeholder text (`'Card title'` → your attribute/content).
4. **DRY it** — if the shape repeats, put it in a `define fragment` and `use` it.

### Worked example — `Card`

`describe building block Atlas_Web_Content.Card` yields the tree shown above. Mirror
it onto a page, binding real content:

```mdl
create page MyModule.CardDemo
(
  title: 'Card demo',
  layout: Atlas_Core.Atlas_Default
)
{
  container myCard (designproperties: ['Card style': on]) {
    dynamictext cardTitle
    (
      content: 'Customers',
      rendermode: H4,
      class: 'card-title',
      designproperties: ['Spacing': ['margin-bottom': 'L']]
    )
  }
};
```

Reusable version — put the card **shell** in a fragment with a `slot`, then fill
the slot with each card's own content. This is the key idiom: one card wrapper,
arbitrary bodies, no copy-paste of the wrapper markup.

```mdl
define fragment SectionCard as {
  container card1 (designproperties: ['Card style': on, 'Spacing': ['margin-bottom': 'Large']]) {
    container cardBody (class: 'card-body') {
      slot content            -- each page's widgets land here
    }
  }
};

create page MyModule.Dashboard
(
  title: 'Dashboard',
  layout: Atlas_Core.Atlas_Default
)
{
  container page1 (class: 'flex-column') {
    use fragment SectionCard {
      dynamictext custTitle (content: 'Customers', rendermode: H4, class: 'card-title')
      dynamictext custBody (content: 'Recent customer activity')
    }
    use fragment SectionCard {
      dynamictext ordTitle (content: 'Orders', rendermode: H4, class: 'card-title')
      datagrid ordGrid (datasource: database MyModule.Order) { }
    }
  }
};
```

The `slot` marker is resolved at expansion — `describe page` shows the fully
wrapped tree (`card1 > cardBody > custTitle, custBody`), and `mx check` is clean.
The slot name is optional (defaults to `content`); a fragment supports one slot.
Use `as prefix_` when the wrapper's *own* widget names would collide across uses
(the payload keeps the names you give it). For a fixed, content-invariant group
(a footer, a button pair) a plain slotless fragment is still the right tool.

**Binding data and behaviour (experimental).** A slot varies *what widgets* go
inside; typed **parameters** vary *which entity* and *which microflow*. Declare a
`datasource` and/or `action` parameter and the card becomes a real component:

```mdl
define fragment EntityCard($data: datasource, $onOpen: action) as {
  container card1 (designproperties: ['Card style': on]) {
    listview lv (datasource: $data) {
      slot content
      actionbutton open (caption: 'Open', action: $onOpen, buttonstyle: primary)
    }
  }
};
use fragment EntityCard ($data: database Sales.Order, $onOpen: microflow Sales.Open) {
  dynamictext cardTitle (content: 'Orders', rendermode: H4, class: 'card-title')
}
```

Atlas **building blocks** can't declare params, but `use building block` takes
rebind overrides that rewrite the block's outermost datasource / first button:

```mdl
use building block Atlas_Web_Content.List_Cards
  (datasource: database Sales.Order, action: microflow Sales.Open) as orders_;
```

For a binding the override rule can't reach, copy the block in (`as prefix_`) and
`alter page … set datasource/action on prefix_widget`.

### Worked example — `Pageheader`

`describe building block Atlas_Web_Content.Pageheader`:

```
{
  container container1 (Class: 'pageheader', DesignProperties: ['Item gap': 'None']) {
    dynamictext text40 (Content: 'Page header title', RenderMode: H1, Class: 'pageheader-title')
    dynamictext text39 (Content: 'Supporting text', RenderMode: Paragraph, Class: 'pageheader-subtitle',
      DesignProperties: ['Color': 'Detail color', 'Spacing': ['margin-bottom': 'None']])
  }
}
```

Mirror:

```mdl
create page MyModule.CustomersHeaderDemo
(
  title: 'Customers',
  layout: Atlas_Core.Atlas_Default
)
{
  container pageHeader (class: 'pageheader', designproperties: ['Item gap': 'None']) {
    dynamictext headerTitle (content: 'Customers', rendermode: H1, class: 'pageheader-title')
    dynamictext headerSubtitle
    (
      content: 'All active accounts',
      rendermode: Paragraph,
      class: 'pageheader-subtitle',
      designproperties: ['Color': 'Detail color', 'Spacing': ['margin-bottom': 'None']]
    )
  }
};
```

### Block → screen map (which block to reach for)

| You want | Mirror this block |
|---|---|
| A titled surface panel | `Card` / `Card_Action` (with a trailing action) / `Card_WithImage` |
| A page title + subtitle band | `Pageheader` (+ `_WithBack` / `_WithControls` / `_WithSearch`) |
| A big splash header | `Heroheader` (+ `_Background` / `_WithAction`) |
| A vertical / horizontal form | `Form_Vertical*` / `Form_Horizontal*` |
| A card/list feed | `List_Cards`, `List_WithImage`, `ListItem_*` |
| A master list + detail pane | `Master_Detail` |
| An activity/history feed | `Timeline` / `Timeline_WithImage` |
| A multi-step flow | `Wizard_Arrow` / `Wizard_Circle` (+ their `_Step`) |
| An inline notice | `Alert`, `AlertIcon` (+ `_WithAction`) |
| A path/breadcrumb trail | `Breadcrumb` / `Breadcrumb_Underline` |

---

## Atlas appearance vocabulary — classes & design properties

Atlas exposes its whole appearance system through the styling channels mxcli can
write today: raw `class:` strings and typed `designproperties:`. **Reach for these
before writing custom CSS.**

### The cheat-sheet

Apply via `class:` on any widget (space-join several: `class:'card flex-column'`).

| Concern | Atlas classes |
|---|---|
| **Cards** | `card`, `cards` (+ Card-style variants) — real CSS, `.card` is ~19 rules |
| **Backgrounds** | `background-{default,main,primary,secondary,success,warning,danger}` |
| **Buttons** | `btn-{primary,secondary,success,warning,danger}`, `btn-{lg,sm,bordered,block,icon-right,icon-top}` |
| **Flex / align** | `flex-{row,column,nowrap,items-grow,items-shrink}`, `align-x-{left,center,right,between,around,evenly}`, `align-y-*` |
| **Spacing utils** | `spacing-{outer,inner}-{top,right,bottom,left}` (+ `-medium` / `-large` / `-none` sizes) |
| **Borders / overflow** | `div-border-toggle-{all,top,…,none}`, `div-overflow-{auto,hidden,visible}` (+ border radius/color/style/width) |
| **Elevation** | `Shadow` toggle |
| **Data grids** | `datagrid-{bordered,hover,striped,lined,lg,sm}` |
| **Group boxes** | `groupbox-{primary,danger,secondary,callout}` |

Source: `atlas_core/web/design-properties.json` (verified in-project). To see what a
specific widget offers, run `show design properties` / `describe styling`
(`theme-styling.md`).

### When to reach for each

- **`card` / `Card style`** — any titled surface panel. This is the workhorse; a
  dashboard is mostly cards on a `background-main` page.
- **`background-primary` / `background-success` / …** — coloured section/hero/status
  surfaces. These resolve to your **retuned brand tokens** (Layer 1), so a hero band
  set to `background-primary` turns *your* brand colour automatically.
- **`btn-*`** — prefer `buttonstyle: primary` on `actionbutton` for the semantic
  style; add `btn-lg` / `btn-bordered` / `btn-block` as classes for size and shape.
- **`flex-row` / `flex-column` + `align-x-*` / `align-y-*`** — layout inside a
  container without a `layoutgrid`. `flex-row` + `align-x-between` is the standard
  "title on the left, action on the right" header row.
- **`spacing-inner-*` / `spacing-outer-*`** — padding/margin without inline `style:`.
- **`datagrid-*`** — reach for these on data grids before overriding grid CSS.
- **`groupbox-*`** — callouts / grouped sections with a semantic tint.

### Typed design properties — the alternative channel

Atlas building blocks use **both** channels side by side. The typed channel is what
Studio Pro's Appearance tab reads, so mirror it when you want the block to round-trip
cleanly into Studio Pro. Common mappings:

| Class-style | Typed design-property equivalent |
|---|---|
| `class:'card'` | `designproperties: ['Card style': on]` |
| `class:'background-primary'` | `designproperties: ['Background color': 'Brand Primary']` |
| `class:'flex-column'` | `designproperties: ['Flex container': 'Vertical (column)']` |
| `class:'flex-row'` | `designproperties: ['Flex container': 'Horizontal (row)']` |
| `class:'align-x-center'` | `designproperties: ['Align items X': 'Center']` |
| `class:'Shadow'` | `designproperties: ['Shadow': 'None' / 'Small' / …]` |
| spacing utilities | `designproperties: ['Spacing': ['margin-bottom': 'L', 'padding-top': 'S']]` |

**Both channels render identically at runtime** — raw `class:` is sufficient for the
visual result today. The typed channel matters for Studio Pro round-trip and is the
more idiomatic form to mirror from a `describe building block`. Notes:
- Design-property **keys are case-sensitive** — match the `describe` output exactly.
- Compound properties (Spacing, Border) take a **nested list**:
  `['Spacing': ['margin-top': 'Large', 'margin-bottom': 'None']]`.
- **Never** put inline `style:` on a `dynamictext` — it crashes MxBuild. Use `class:`
  or wrap in a styled `container`. (`theme-styling.md`.)

---

## Brand re-tune (Layer 1) — where most of the win is

Copy the scaffold below into `theme/web/custom-variables.scss` and set the
placeholder palette. Because Atlas utilities and pluggable widgets read these tokens,
one retune re-skins the whole app:

- `--brand-primary` → buttons, `background-primary`, links, Switch/Slider/ProgressBar
- background + semantic (`success`/`warning`/`danger`) tokens → alerts, group boxes,
  status backgrounds
- `--card-border-radius` and radius tokens → cards, inputs, popups (drop to `0` for a
  sharp, industrial identity; raise for a soft, friendly one)

Only after the token retune, reach for Layer-2 identity classes in `main.scss` — and
only for shapes Atlas can't provide.

---

## Layer-1 brand scaffold — copy into theme/web/custom-variables.scss

```scss
// =============================================================================
// Layer 1 — BRAND: retune Atlas tokens
// -----------------------------------------------------------------------------
// Copy this into  theme/web/custom-variables.scss  and swap the placeholder
// palette below for your brand.
//
// WHY THIS FILE MATTERS: Atlas classes and pluggable widgets READ these tokens.
// Retuning them here cascades the palette DOWN into buttons, `background-*`
// utilities, form inputs, cards, popups, and pluggable widgets (Switch, Slider,
// RangeSlider, ProgressBar, ProgressCircle, BadgeButton) — with NO per-widget CSS.
// This is the single highest-leverage styling change you can make.
//
// These vars use Atlas's `!default` chain, so they override
// atlas_core/web/variables.scss. See `theme-styling.md` for the compile order.
// Reach for THIS layer before writing any custom class in main.scss (Layer 2).
// =============================================================================

// 1. BRAND PRIMARY — the one colour that defines the app.
//    Flows into: btn-primary, background-primary, links, active nav, and the
//    brand-reading pluggable widgets (Switch / Slider / ProgressBar / …).
$brand-primary:   #2b5170 !default;   // TODO: your brand colour
$brand-secondary: #5c6a78 !default;   // TODO: muted / secondary accent

// 2. SEMANTIC COLOURS — success / warning / danger / info.
//    Flows into: btn-*, background-*, groupbox-*, alerts, status surfaces.
$brand-success: #4a7a5c !default;   // TODO
$brand-warning: #c9a227 !default;   // TODO
$brand-danger:  #a13a2c !default;   // TODO
$brand-info:    #2f6f9f !default;   // TODO

// 3. BACKGROUNDS & INK — the neutral ground the app sits on. Retune these so
//    Atlas surfaces OUTSIDE your scoped classes (form inputs, popups, modals)
//    inherit the palette too.
$bg-color:              #eef1f4 !default;   // TODO: app background
$background-color-page: $bg-color !default;
$font-color-default:    #1a2129 !default;   // TODO: body ink
$font-color-detail:     #5c6a78 !default;   // TODO: secondary / muted text
$border-color-default:  #dde3ea !default;   // TODO: hairline borders

// Form inputs — keeps inputs on-palette everywhere (incl. popups).
$form-input-bg:           #ffffff !default;   // TODO
$form-input-border-color: $border-color-default !default;
$form-input-color:        $font-color-default !default;

// 4. SHAPE — corner radius. 0 = sharp/industrial; higher = soft/friendly.
//    Cascades into cards, inputs, buttons, popups.
$border-radius-default: 8px !default;   // TODO: 0 … 16px
$card-border-radius:    $border-radius-default !default;

// 5. TYPOGRAPHY — set a brand font. If it is a WEB font, `@import` it as the
//    FIRST line of main.scss (an @import after any rule is silently dropped), and
//    ALWAYS keep a system fallback stack so the layout survives a font-load fail.
$font-family-base: "system-ui", -apple-system, "Segoe UI", sans-serif !default;   // TODO

// Bridge Atlas CSS custom properties to the Sass vars above, so runtime CSS
// (`var(--brand-primary)`, `background-primary`, etc.) resolves to your palette.
:root {
  --brand-primary:   #{$brand-primary};
  --brand-secondary: #{$brand-secondary};
  --brand-success:   #{$brand-success};
  --brand-warning:   #{$brand-warning};
  --brand-danger:    #{$brand-danger};
  --brand-info:      #{$brand-info};

  --bg-color:             #{$bg-color};
  --font-color-default:   #{$font-color-default};
  --font-color-detail:    #{$font-color-detail};
  --border-color-default: #{$border-color-default};
  --card-border-radius:   #{$card-border-radius};
  --font-family-base:     #{$font-family-base};
}
```

---

## Charts — a dataviz-grade theme for the Mendix chart widgets

Out of the box the chart widgets (Column / Bar / Area / Pie / Line) render **raw
Plotly defaults**: one flat colour, a floating mode-bar, wide margins, heavy
gridlines, a white paper background. That is the single biggest "not a real product"
tell. Three Plotly hooks — barely used by generated apps — turn them into designed
charts. All three are **plain JSON strings** (no Mendix expression quoting).

| Property | Plotly layer | Use it for |
|---|---|---|
| `customLayout` | `layout` | transparent `paper_bgcolor` + `plot_bgcolor`, system font, `#8a94a6` ticks, tight `margin`, faint `gridcolor`, `zeroline:false` / `showline:false`, dark `hoverlabel` |
| `customConfigurations` | `config` | `{"displayModeBar":false,"responsive":true}` — removes the floating toolbar |
| `customSeriesOptions` (per series; chart-level on Pie) | trace | brand colour, `marker.cornerradius` (rounded bars), `line.shape:"spline"` + translucent `fillcolor` (area), Pie colour array + white inside labels |

**The key trick — transparent background = theme-agnostic charts.** Set
`paper_bgcolor` and `plot_bgcolor` to `rgba(0,0,0,0)`; the plot inherits whatever
panel it sits on, so **one config is correct in both light and dark** with zero
per-theme CSS. Pair it with a neutral tick colour (`#8a94a6`) that reads on either
background. Always kill the white paper **and** the mode-bar — the two ugliest
defaults.

Ready-made `customLayout` (transparent, themed):
```json
{
  "paper_bgcolor": "rgba(0,0,0,0)",
  "plot_bgcolor": "rgba(0,0,0,0)",
  "font": { "family": "system-ui, -apple-system, 'Segoe UI', sans-serif", "color": "#8a94a6" },
  "margin": { "t": 8, "r": 8, "b": 32, "l": 40 },
  "xaxis": { "gridcolor": "rgba(138,148,166,0.15)", "zeroline": false, "showline": false },
  "yaxis": { "gridcolor": "rgba(138,148,166,0.15)", "zeroline": false, "showline": false },
  "hoverlabel": { "bgcolor": "#1a2129", "font": { "color": "#ffffff" } }
}
```

`customConfigurations` (kill the mode-bar): `{ "displayModeBar": false, "responsive": true }`

`customSeriesOptions` per type:
```jsonc
// Column / Bar — brand colour + rounded corners
{ "marker": { "color": "#2b5170", "cornerradius": 6 } }
// Area — spline curve + translucent fill
{ "line": { "shape": "spline", "color": "#2b5170" }, "fill": "tozeroy", "fillcolor": "rgba(43,81,112,0.15)" }
// Pie (chart-level) — colour array + white inside labels
{ "marker": { "colors": ["#2b5170", "#4a7a5c", "#c9a227", "#a13a2c"] }, "insidetextfont": { "color": "#ffffff" } }
```

Swap the hex values for your brand palette (the same values you set in the Layer-1
scaffold). The generic `dataviz` skill is the HTML/React analogue of this — same
"kill the defaults, one theme-agnostic config, brand the series" philosophy.

**Chart gotchas** are in the [gotchas catalog](#gotchas-catalog). All chart types
(incl. Line/Bubble/Heatmap/TimeSeries) are MDL-authorable today — see
`mdl-examples/doctype-tests/34-chart-widget-examples.mdl` and `custom-widgets.md`.

---

## Dark mode — commit to one theme

A `prefers-color-scheme: dark` flip repaints **your** custom chrome, but Atlas's own
widgets and Plotly ship **light-only** surfaces — on a dark page they render as white
boxes with (often) near-invisible text. **Decide theme-count up front:**

- A **dark-only** app is simpler and more robust — drop the `@media` gate and make
  the widget overrides **unconditional + global** (this also covers portal-rendered
  popups/modals that live outside your scoped class).
- If you can't fund the override recipe, ship **light-only**. A half-dark result
  (your chrome dark, Atlas widgets light) is **worse** than a consistent light app.

Charts are the exception — don't CSS them; use the transparent `customLayout` trick
above, which adapts to light **and** dark automatically.

---

## Optional dark-mode Atlas-widget overrides

Paste into `main.scss` (Layer 2), after the `@import`s. Replace the token
placeholders with your dark palette. Popovers/modals render at `<body>`, so the
popover + modal block must **not** be scoped to your app class — keep it global.

```scss
// --- Dark palette tokens (TODO: set these) ----------------------------------
$dk-surface: #1a2129;   // panel / row background
$dk-surface-2: #232c37; // header / chip background
$dk-ink:     #e6ebf1;   // primary text
$dk-ink-mut: #9aa6b4;   // muted text
$dk-border:  #2f3a47;   // hairline

// Wrap in the media query for a dual-theme app; DELETE the @media line (and its
// closing brace) for a committed dark-only app to make these unconditional.
@media (prefers-color-scheme: dark) {

  // Form controls: text input / textarea / combobox field
  .form-control,
  .mx-textarea textarea,
  .form-control input {
    background: $dk-surface; color: $dk-ink; border-color: $dk-border;
  }

  // Datagrid: rows, headers, filter chips
  .mx-datagrid table, .mx-datagrid tr, .mx-datagrid th, .mx-datagrid td {
    background: $dk-surface; color: $dk-ink; border-color: $dk-border;
  }
  .filter-selector-button {
    background: $dk-surface-2; color: $dk-ink; border-color: $dk-border;
  }

  // Datagrid dropdown filter: kill the hardcoded white scroll-fade gradient
  .widget-dropdown-filter-menu {
    background-image: none; background-color: $dk-surface;
  }
  .widget-dropdown-filter-menu * { color: $dk-ink; }

  // Accordion / Fieldset
  .mx-groupbox, .mx-groupbox-header, fieldset, legend {
    background: $dk-surface; color: $dk-ink; border-color: $dk-border;
  }

  // TreeNode: expanded child rows carry a WHITE card bg — let the panel show through
  .mx-treenode, .mx-treenode .mx-treenode-content {
    background: transparent; color: $dk-ink;
  }
}

// Popovers / modals render at <body> — theme these GLOBALLY (unscoped).
// Combobox / tooltip / dropdown-filter popovers and edit popups (.mx-window /
// .modal-content) live outside your app class, so a scoped selector misses them.
.mx-window-content, .modal-content, .mx-window-header, .mx-tooltip, .mx-combobox-menu {
  background: $dk-surface; color: $dk-ink; border-color: $dk-border;
}
.mx-window-content .form-control, .modal-content .form-control {
  background: $dk-surface-2; color: $dk-ink; border-color: $dk-border;
}
.mx-window .btn-default, .modal-content .btn-default {
  background: $dk-surface-2; color: $dk-ink; border-color: $dk-border;
}
// Charts: DON'T style them here — use the transparent customLayout (above).
```

---

## Verify at runtime — this is mandatory

**Runtime verification is not optional.** `mx check` (and `mxcli check --references`)
validate the *model* — they pass MDL the **browser client still crashes on**:

- an old ListView carrying `SearchRefs` the client can't render;
- the Slider / RangeSlider tooltip calling React's removed `findDOMNode` — this only
  throws **on drag**, so a static check (even a static screenshot) misses it;
- a structural change that leaves the client bundle unbuilt (blank `<noscript>` shell).

A model that checks clean can still render a white page. **Never ship on `mx check`
alone.** Keep the app hot and screenshot every change:

```bash
mxcli run --local -p app.mpr --watch --screenshot
```

- **SCSS / theme edits hot-apply** (~1 s) — no restart. Layer-1
  (`custom-variables.scss`) and Layer-2 (`main.scss`) both reflect on the next shot.
- **Page / microflow / text edits hot-apply** too (`reload_model`, ~1 s).
- **Structural changes restart + DDL** (~9 s): a new entity, view entity, or
  association is reconciled only at runtime startup, so `run --local` restarts
  automatically. A hot `reload` won't see a new entity — expect the restart.
- `--screenshot` writes a Playwright PNG (default `<projectDir>/.mxcli/run-local.png`)
  after boot and after **each** applied change.
- `--screenshot-url /p/customers` targets a specific page (repeatable — one PNG each).
- `--screenshot-user` / `--screenshot-password` log in once for pages behind login.

**From an egress-only environment (Claude Code web):** `--hub <url>` reverse-tunnels
the local app out over a single 443 connection to a relay, giving a public URL you can
open in a real browser. `--hub` implies `--local`. See `run-local.md` for the flags.

**What a screenshot can't catch — drive the interaction.** A single screenshot is a
static frame; the Slider `findDOMNode` throw fires on drag, a filter popover's white
gradient only shows when opened. For interactive widgets, either screenshot the
interacted state or set the safe default up front (Slider `showTooltip: false`).

The rhythm: keep terminal 1 hot (`run --local --watch --screenshot`); in terminal 2
apply one slice (`mxcli exec 06-redesign.mdl -p app.mpr`) and look at the PNG. A
designed result is reached by looking at the running app, not by trusting the checker.

---

## Gotchas catalog

Each cost real time in the builds this skill was distilled from. Match a symptom to a
row before opening files.

### Styling & pages

| Gotcha | Fix |
|---|---|
| `$` in `dynamictext content:` breaks the parser (starts a variable token) | put the `$` in CSS `::before`; bind only the number |
| Enum `dynamictext` renders the **key**, not the caption | accept it, or map the enum to a class via `dynamicclasses` |
| `sort by` not allowed on **association-sourced** listviews | sort the parent, or use a DB datasource |
| Reserved widget identifiers exist (e.g. `v3`) | prefix names (`sv3`); avoid bare `v<n>` |
| Pluggable widgets impose their own DOM (charts / timeline / treenode) | for pixel-fidelity use a native `listview` / `gallery` you fully style |
| Inline `style:` on a `dynamictext` crashes MxBuild (NullReferenceException) | use `class:`, or wrap the text in a styled `container` |
| `alter styling` can't find widgets in MDL-builder-created pages | apply classes via `Class:` / `DynamicClasses:` in `create page` / `alter page` |
| Full-screen page wanted (no Atlas sidebar) but no blank layout resolves | keep a normal Atlas layout; hide the shell per-page with `.mx-page:has(.my-app) .region-sidebar { display:none }` |
| "Colour by state" (status pills / cards) | one `dynamicclasses` enum→class expression + one `--st` CSS var cascaded into pill/number/dot/border |

### Charts

| Gotcha | Fix |
|---|---|
| Chart widgets render **raw Plotly defaults** (flat colour, floating mode-bar, white paper, heavy grid) | `customLayout` (transparent bg + system font + faint grid) + `customConfigurations` `displayModeBar:false` + per-series `customSeriesOptions` (colour, `cornerradius`, spline) |
| Horizontal **BarChart** with `aggregationType: sum` prepends a `0` group-key to category ticks (`"0Tokyo Spring"`) | use `aggregationType: none` when the datasource is already one row per category |
| **Chart colours don't re-skin** — series colour lives in the model (`customSeriesOptions`), not CSS | accept it's model config; a palette pivot needs an MDL edit + gen-2 restart, not a theme edit |

### Dark mode & widgets

| Gotcha | Fix |
|---|---|
| Atlas widgets + Plotly **aren't dark-aware** — a `prefers-color-scheme` flip leaves them light on a dark page | ship the dark-mode override block above (form controls, datagrid + filters/popovers, accordion, fieldset, **treenode white rows**, transparent charts), or ship light-only |
| `.widget-dropdown-filter-menu` paints a **hardcoded white scroll-fade gradient** even after bg is themed | override `background-image:none` and brighten menu-item text |
| **Edit popup has a white title bar** — `.mx-window` / `.modal-content` renders at `<body>`, outside your scoped class | theme `.mx-window-content` / `.modal-content` + header + form controls/buttons **globally**, not scoped |
| **Slider / RangeSlider** throw "Could not render widget" on drag (tooltip calls React `findDOMNode`, removed in MX 11) | set `showTooltip: false` |
| Half-dark clash (your chrome dark, Atlas widgets light) | **commit to one theme**: for a dark app drop the media gate and make overrides unconditional + global; ship **light-only** if you can't fund the override recipe |

### Theme / SCSS

| Gotcha | Fix |
|---|---|
| Google-fonts `@import url()` silently dropped | make it the **first line** of `main.scss` (before the partial import and any rule); keep a system fallback stack |
| Full re-skin desired (new identity) | it's **theme-only** — retune `custom-variables.scss` (Atlas leaves) + `main.scss` (custom tokens + classes); no page/MDL edits, hot-applies under `--watch` |
| "SCSS cache" — edits don't show | it's never a cache: use `--watch` (watches theme source) or a clean restart; kill any stale process first |
| Stale process serves old output, looks like a cache | `run --local` refuses occupied ports; free them (`pgrep`/`kill`, `curl` returns 000 when down) |

### Data / microflows behind the design (styling depends on real data)

| Gotcha | Fix |
|---|---|
| Seed microflow data doesn't appear (queries empty) | **`create` doesn't persist — add `commit $obj;`**; the miss is silent (no error) |
| Bare `$x = avg(...)` or `$x = 2` fails to parse | bare `$x = …` accepts only `count`/`sum` aggregates; use `declare $x T = expr` for other expressions, `set $x = expr` to reassign |
| Aggregates can't be inlined in a create-object assignment (CE0117) | compute into vars first |
| Integer/integer division `$a / $b` → CE0117 | Mendix `/` needs a decimal operand; compute upstream or store decimals |
| View entity flagged CE6770 "out of sync" | the view's declared attribute types must match its OQL source columns; a grouped enum column must be typed `enumeration(Module.Enum)`, not `string` |

### Verify

| Gotcha | Fix |
|---|---|
| **`mx check` passes but the browser client crashes** (old ListView `SearchRefs`; the Slider `findDOMNode` throw only fires on interaction) | **always Playwright-verify a running build; never ship on `mx check` alone** |
| `ALTER PAGE SET layout … map(…)` swaps a page onto a sidebar shell | it does so without rebuilding the widget tree — use it to re-parent, not to rebuild |

---

## Validation Checklist

- [ ] **Atlas-first** — reached for `class:`/design properties (Layer 0) and brand
      tokens (Layer 1) before any custom CSS
- [ ] **Discovered** the project's building blocks (`show building blocks`) and
      **inspected** the target block (`describe building block …`) before using it
- [ ] **Instantiated** with `use building block Mod.Name [as prefix_]` (the one-liner),
      then configured the copied widgets with `alter page` — mirrored by hand only as a
      deliberate fallback
- [ ] **Brand tokens retuned** in `theme/web/custom-variables.scss` so Atlas
      components inherit the palette; custom SCSS reserved for identity only
- [ ] **Committed to a theme count** up front (light-only or dark-only beats half-dark)
- [ ] **Charts themed** with transparent `customLayout` + `displayModeBar:false`
      when the app has charts
- [ ] **Runtime-verified** with `run --local --watch --screenshot` — never shipped
      on `mx check` alone
- [ ] Every MDL snippet passes `mxcli check`

## Related skills

- `theme-styling.md` — SCSS compilation chain, hot-reload, styling caveats
- `migrate-design-prototype.md` — turning a Claude Design handoff into a theme + pages
- `create-page.md` — page/widget syntax
- `alter-page.md` — in-place widget edits
- `fragments.md` — reusable widget groups (how the mirror recipes stay DRY)
- `run-local.md` — the warm dev loop and screenshot flags
