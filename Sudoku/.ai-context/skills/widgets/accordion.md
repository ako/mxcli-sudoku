# Accordion

- **Widget ID:** `com.mendix.widget.web.accordion.Accordion`
- **Type:** PLUGGABLEWIDGET
- **Version:** 2.3.4

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.accordion.Accordion' widget1 {
  group item1   -- one entry of `groups`
}
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `advancedMode` | boolean | Yes | false |  |
| `groups` | object | Yes |  |  |
| `collapsible` | boolean | Yes | true |  |
| `expandBehavior` | enumeration | Yes | singleExpanded | Allow a single group or multiple groups to be expanded at the same time. |
| `animate` | boolean | Yes | true |  |
| `showIcon` | enumeration | Yes | right |  |
| `icon` | icon |  |  |  |
| `expandIcon` | icon |  |  |  |
| `collapseIcon` | icon |  |  |  |
| `animateIcon` | boolean | Yes | true | Animate the icon when the group is collapsing or expanding. |

## Object Lists (repeating child entries)

### `group` → property `groups`

Item properties:

| Property | Operation |
|----------|-----------|
| `headerRenderMode` | primitive |
| `headerText` | texttemplate |
| `headerHeading` | primitive |
| `visible` | expression |
| `dynamicClass` | expression |
| `loadContent` | primitive |
| `initialCollapsedState` | primitive |
| `initiallyCollapsed` | expression |
| `collapsed` | attribute |
| `onToggleCollapsed` | action |

Item child slots:

| MDL keyword | Widget property |
|-------------|----------------|
| `headercontent` | `headerContent` |
| `content` | `content` |

