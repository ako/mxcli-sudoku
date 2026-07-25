# Range Slider

- **Widget ID:** `com.mendix.widget.custom.RangeSlider.RangeSlider`
- **Type:** PLUGGABLEWIDGET
- **Version:** 2.1.4

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.custom.RangeSlider.RangeSlider' widget1
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `lowerBoundAttribute` | attribute |  |  | The lower bound value on the slider |
| `upperBoundAttribute` | attribute |  |  | The upper bound value on the slider |
| `advanced` | boolean |  | false |  |
| `minValueType` | enumeration |  | static |  |
| `staticMinimumValue` | decimal |  | 0 |  |
| `minAttribute` | attribute |  |  |  |
| `expressionMinimumValue` | expression |  |  |  |
| `maxValueType` | enumeration |  | static |  |
| `staticMaximumValue` | decimal |  | 100 |  |
| `maxAttribute` | attribute |  |  |  |
| `expressionMaximumValue` | expression |  |  |  |
| `stepSizeType` | enumeration |  | static |  |
| `stepValue` | decimal |  | 1 |  |
| `stepAttribute` | attribute |  |  |  |
| `expressionStepSize` | expression |  |  |  |
| `showTooltip` | boolean |  | true |  |
| `tooltipTypeLower` | enumeration |  | value | By default tooltip shows current value. Choose 'Custom' to create your own te... |
| `tooltipLower` | textTemplate |  |  |  |
| `tooltipTypeUpper` | enumeration |  | value | By default tooltip shows current value. Choose 'Custom' to create your own te... |
| `tooltipUpper` | textTemplate |  |  |  |
| `tooltipAlwaysVisible` | boolean |  | false | When enabled tooltip is always visible to the user |
| `noOfMarkers` | integer |  | 1 | Marker ticks on the slider (visible when larger than 0) |
| `decimalPlaces` | integer |  | 0 | Number of decimal places for marker values |
| `orientation` | enumeration |  | horizontal | If orientation is 'Vertical', make sure that parent or slider itself has fixe... |
| `heightUnit` | enumeration |  | percentage |  |
| `height` | integer |  | 100 |  |
| `onChange` | action |  |  |  |

