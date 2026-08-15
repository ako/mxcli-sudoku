# Drop-down sort

- **Widget ID:** `com.mendix.widget.web.dropdownsort.DropdownSort`
- **Type:** PLUGGABLEWIDGET
- **Version:** 3.3.0

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.dropdownsort.DropdownSort' widget1
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `linkedDs` | datasource | Yes |  |  |
| `attributes` | object |  |  | Select the attributes that the end-user may use for sorting |
| `emptyOptionCaption` | textTemplate |  |  |  |
| `screenReaderButtonCaption` | textTemplate |  |  | Assistive technology will read this upon reaching the sort order button. |
| `screenReaderInputCaption` | textTemplate |  |  | Assistive technology will read this upon reaching the input element. |

