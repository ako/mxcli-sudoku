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
| `lowerBoundAttribute` | attribute | Yes |  | The lower bound value on the slider |
| `upperBoundAttribute` | attribute | Yes |  | The upper bound value on the slider |
| `advanced` | boolean | Yes | false |  |
| `minValueType` | enumeration | Yes | static |  |
| `staticMinimumValue` | decimal | Yes | 0 |  |
| `minAttribute` | attribute |  |  |  |
| `expressionMinimumValue` | expression |  |  |  |
| `maxValueType` | enumeration | Yes | static |  |
| `staticMaximumValue` | decimal | Yes | 100 |  |
| `maxAttribute` | attribute |  |  |  |
| `expressionMaximumValue` | expression |  |  |  |
| `stepSizeType` | enumeration | Yes | static |  |
| `stepValue` | decimal | Yes | 1 |  |
| `stepAttribute` | attribute |  |  |  |
| `expressionStepSize` | expression |  |  |  |
| `showTooltip` | boolean | Yes | true |  |
| `tooltipTypeLower` | enumeration | Yes | value | By default tooltip shows current value. Choose 'Custom' to create your own te... |
| `tooltipLower` | textTemplate |  |  |  |
| `tooltipTypeUpper` | enumeration | Yes | value | By default tooltip shows current value. Choose 'Custom' to create your own te... |
| `tooltipUpper` | textTemplate |  |  |  |
| `tooltipAlwaysVisible` | boolean | Yes | false | When enabled tooltip is always visible to the user |
| `noOfMarkers` | integer | Yes | 1 | Marker ticks on the slider (visible when larger than 0) |
| `decimalPlaces` | integer | Yes | 0 | Number of decimal places for marker values |
| `orientation` | enumeration | Yes | horizontal | If orientation is 'Vertical', make sure that parent or slider itself has fixe... |
| `heightUnit` | enumeration | Yes | percentage |  |
| `height` | integer | Yes | 100 |  |
| `onChange` | action |  |  |  |

