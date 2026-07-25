# Selection helper

- **Widget ID:** `com.mendix.widget.web.selectionhelper.SelectionHelper`
- **Type:** PLUGGABLEWIDGET
- **Version:** 3.3.0

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.selectionhelper.SelectionHelper' widget1 {
  customallselected {
    -- widgets for `customAllSelected`
  }
  customsomeselected {
    -- widgets for `customSomeSelected`
  }
  customnoneselected {
    -- widgets for `customNoneSelected`
  }
}
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `renderStyle` | enumeration |  | checkbox | Custom enables placeholders for using widgets for the different states. |
| `checkboxCaption` | textTemplate |  |  |  |
| `customAllSelected` | widgets |  |  |  |
| `customSomeSelected` | widgets |  |  |  |
| `customNoneSelected` | widgets |  |  |  |

## Child Slots (curly-brace blocks)

| MDL keyword | Widget property |
|-------------|----------------|
| `customallselected` | `customAllSelected` |
| `customsomeselected` | `customSomeSelected` |
| `customnoneselected` | `customNoneSelected` |

