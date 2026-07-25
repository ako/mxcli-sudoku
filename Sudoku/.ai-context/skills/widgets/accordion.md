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
| `advancedMode` | boolean |  | false |  |
| `groups` | object | Yes |  |  |
| `collapsible` | boolean |  | true |  |
| `expandBehavior` | enumeration |  | singleExpanded | Allow a single group or multiple groups to be expanded at the same time. |
| `animate` | boolean |  | true |  |
| `showIcon` | enumeration |  | right |  |
| `icon` | icon |  |  |  |
| `expandIcon` | icon |  |  |  |
| `collapseIcon` | icon |  |  |  |
| `animateIcon` | boolean |  | true | Animate the icon when the group is collapsing or expanding. |

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

