# Progress circle

- **Widget ID:** `com.mendix.widget.custom.progresscircle.ProgressCircle`
- **Type:** PLUGGABLEWIDGET
- **Version:** 3.3.2

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.custom.progresscircle.ProgressCircle' widget1 {
  customlabel {
    -- widgets for `customLabel`
  }
}
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `type` | enumeration |  | static |  |
| `staticCurrentValue` | integer |  | 50 |  |
| `dynamicCurrentValue` | attribute |  |  |  |
| `expressionCurrentValue` | expression |  |  |  |
| `staticMinValue` | integer |  | 0 |  |
| `dynamicMinValue` | attribute |  |  |  |
| `expressionMinValue` | expression |  |  |  |
| `staticMaxValue` | integer |  | 100 |  |
| `dynamicMaxValue` | attribute |  |  |  |
| `expressionMaxValue` | expression |  |  |  |
| `onClick` | action |  |  |  |
| `showLabel` | boolean |  | false |  |
| `labelType` | enumeration |  | text |  |
| `labelText` | textTemplate |  |  |  |
| `customLabel` | widgets |  |  |  |

## Child Slots (curly-brace blocks)

| MDL keyword | Widget property |
|-------------|----------------|
| `customlabel` | `customLabel` |

