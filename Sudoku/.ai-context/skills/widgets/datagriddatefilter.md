# Date filter

- **Widget ID:** `com.mendix.widget.web.datagriddatefilter.DatagridDateFilter`
- **Type:** PLUGGABLEWIDGET
- **Version:** 3.4.0

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.datagriddatefilter.DatagridDateFilter' widget1
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `attrChoice` | enumeration | Yes | auto |  |
| `linkedDs` | datasource | Yes |  |  |
| `attributes` | object |  |  | Select the attributes that the end-user may use for filtering. |
| `defaultValue` | expression |  |  |  |
| `defaultStartDate` | expression |  |  |  |
| `defaultEndDate` | expression |  |  |  |
| `defaultFilter` | enumeration | Yes | equal |  |
| `placeholder` | textTemplate |  |  |  |
| `adjustable` | boolean | Yes | true |  |
| `valueAttribute` | attribute |  |  | Attribute used to store the last value of the filter. |
| `startDateAttribute` | attribute |  |  | Attribute used to store the last value of the start date filter. |
| `endDateAttribute` | attribute |  |  | Attribute used to store the last value of the end date filter. |
| `onChange` | action |  |  | Action to be triggered when the value or filter changes. |
| `screenReaderButtonCaption` | textTemplate |  |  | Assistive technology will read this upon reaching the comparison button that ... |
| `screenReaderCalendarCaption` | textTemplate |  |  | Assistive technology will read this upon reaching the button that triggers th... |
| `screenReaderInputCaption` | textTemplate |  |  | Assistive technology will read this upon reaching the input element. |

