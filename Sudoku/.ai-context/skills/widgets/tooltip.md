# Tooltip

- **Widget ID:** `com.mendix.widget.web.tooltip.Tooltip`
- **Type:** PLUGGABLEWIDGET
- **Version:** 1.4.2

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.tooltip.Tooltip' widget1 {
  trigger {
    -- widgets for `trigger`
  }
  htmlmessage {
    -- widgets for `htmlMessage`
  }
}
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `trigger` | widgets | Yes |  |  |
| `renderMethod` | enumeration | Yes | text |  |
| `htmlMessage` | widgets |  |  |  |
| `textMessage` | textTemplate |  |  |  |
| `tooltipPosition` | enumeration | Yes | top | How to position the tooltip in relation to the trigger element - at the top, ... |
| `arrowPosition` | enumeration | Yes | none | How to position the tooltip arrow in relation to the tooltip - at the start, ... |
| `openOn` | enumeration | Yes | hover | How the tooltip is triggered - click, hover, hover and focus. On mobile devic... |

## Child Slots (curly-brace blocks)

| MDL keyword | Widget property |
|-------------|----------------|
| `trigger` | `trigger` |
| `htmlmessage` | `htmlMessage` |

