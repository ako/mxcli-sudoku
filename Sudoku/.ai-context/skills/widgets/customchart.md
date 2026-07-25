# Custom chart

- **Widget ID:** `com.mendix.widget.web.customchart.CustomChart`
- **Type:** PLUGGABLEWIDGET
- **Version:** 6.2.1

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.customchart.CustomChart' widget1 {
  playground {
    -- widgets for `playground`
  }
}
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `dataStatic` | string |  |  | Data JSON array based on https://plot.ly/javascript/reference/ |
| `dataAttribute` | attribute |  |  | The attribute data will merge and overwrite 'Static' data |
| `sampleData` | string |  |  | Data for preview. It will be merged with the 'Static data' in the web modeler... |
| `showPlaygroundSlot` | boolean |  | false |  |
| `playground` | widgets |  |  |  |
| `layoutStatic` | string |  |  | JSON object based on https://plot.ly/javascript/reference/ |
| `layoutAttribute` | attribute |  |  | Attribute layout will merge and overwrite static layout options |
| `sampleLayout` | string |  |  | Layout options for preview. It will be merged with the 'Static' in the web mo... |
| `configurationOptions` | string |  |  | The JSON containing the Plotly configuration options |
| `widthUnit` | enumeration |  | percentage |  |
| `width` | integer |  | 100 |  |
| `heightUnit` | enumeration |  | percentageOfWidth |  |
| `height` | integer |  | 100 |  |
| `minHeightUnit` | enumeration |  | none |  |
| `minHeight` | integer |  | 250 |  |
| `maxHeightUnit` | enumeration |  | none |  |
| `maxHeight` | integer |  | 250 |  |
| `OverflowY` | enumeration |  | auto |  |
| `onClick` | action |  |  |  |
| `eventDataAttribute` | attribute |  |  | The attribute to store received raw data from the chart event. https://plot.l... |

## Child Slots (curly-brace blocks)

| MDL keyword | Widget property |
|-------------|----------------|
| `playground` | `playground` |

