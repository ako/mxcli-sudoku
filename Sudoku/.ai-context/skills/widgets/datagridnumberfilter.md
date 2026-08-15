# Number filter

- **Widget ID:** `com.mendix.widget.web.datagridnumberfilter.DatagridNumberFilter`
- **Type:** PLUGGABLEWIDGET
- **Version:** 3.4.0

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.datagridnumberfilter.DatagridNumberFilter' widget1
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `attrChoice` | enumeration | Yes | auto |  |
| `linkedDs` | datasource | Yes |  |  |
| `attributes` | object |  |  | Select the attributes that the end-user may use for filtering. |
| `defaultValue` | expression |  |  |  |
| `defaultFilter` | enumeration | Yes | equal |  |
| `placeholder` | textTemplate |  |  |  |
| `adjustable` | boolean | Yes | true |  |
| `delay` | integer | Yes | 500 | Wait this period before applying then change(s) to the filter |
| `valueAttribute` | attribute |  |  | Attribute used to store the last value of the filter. |
| `onChange` | action |  |  | Action to be triggered when the value or filter changes. |
| `screenReaderButtonCaption` | textTemplate |  |  | Assistive technology will read this upon reaching the comparison button that ... |
| `screenReaderInputCaption` | textTemplate |  |  | Assistive technology will read this upon reaching the input element. |

