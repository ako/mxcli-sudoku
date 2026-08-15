# Accessibility helper

- **Widget ID:** `com.mendix.widget.web.accessibilityhelper.AccessibilityHelper`
- **Type:** PLUGGABLEWIDGET
- **Version:** 2.2.1

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.accessibilityhelper.AccessibilityHelper' widget1 {
  template {
    -- widgets for `content`
  }
  attr item1   -- one entry of `attributesList`
}
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `targetSelector` | string | Yes |  | Selector to find the first HTML element you want to target which must be a va... |
| `content` | widgets | Yes |  |  |
| `attributesList` | object |  |  |  |

## Child Slots (curly-brace blocks)

| MDL keyword | Widget property |
|-------------|----------------|
| `template` | `content` |

## Object Lists (repeating child entries)

### `attr` → property `attributesList`

Item properties:

| Property | Operation |
|----------|-----------|
| `attribute` | primitive |
| `valueSourceType` | primitive |
| `valueExpression` | expression |
| `valueText` | texttemplate |
| `attributeCondition` | expression |

