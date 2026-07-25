# Progress Bar

- **Widget ID:** `com.mendix.widget.custom.progressbar.ProgressBar`
- **Type:** PLUGGABLEWIDGET
- **Version:** 3.2.2

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.custom.progressbar.ProgressBar' widget1 {
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
| `labelType` | enumeration |  | text | Note: If the Size of the progress bar is set to "Small" in the Appearance tab... |
| `labelText` | textTemplate |  |  |  |
| `customLabel` | widgets |  |  |  |

## Child Slots (curly-brace blocks)

| MDL keyword | Widget property |
|-------------|----------------|
| `customlabel` | `customLabel` |

