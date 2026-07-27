# Slider

- **Widget ID:** `com.mendix.widget.custom.slider.Slider`
- **Type:** PLUGGABLEWIDGET
- **Version:** 2.1.4

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.custom.slider.Slider' widget1
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `valueAttribute` | attribute |  |  |  |
| `advanced` | boolean |  | false |  |
| `minValueType` | enumeration |  | static |  |
| `staticMinimumValue` | decimal |  | 0 | The minimum value of the slider. |
| `minAttribute` | attribute |  |  | The minimum value of the slider. |
| `expressionMinimumValue` | expression |  |  | The minimum value of the slider. |
| `maxValueType` | enumeration |  | static |  |
| `staticMaximumValue` | decimal |  | 100 | The maximum value of the slider. |
| `maxAttribute` | attribute |  |  | The maximum value of the slider. |
| `expressionMaximumValue` | expression |  |  | The maximum value of the slider. |
| `stepSizeType` | enumeration |  | static |  |
| `stepValue` | decimal |  | 1 | Value to be added or subtracted on each step the slider makes. Must be greate... |
| `stepAttribute` | attribute |  |  | Value to be added or subtracted on each step the slider makes. Must be greate... |
| `expressionStepSize` | expression |  |  | Value to be added or subtracted on each step the slider makes. Must be greate... |
| `showTooltip` | boolean |  | true |  |
| `tooltipType` | enumeration |  | value | By default tooltip shows current value. Choose 'Custom' to create your own te... |
| `tooltip` | textTemplate |  |  |  |
| `tooltipAlwaysVisible` | boolean |  | false | When enabled tooltip is always visible to the user |
| `noOfMarkers` | integer |  | 2 | The number of marker ticks that appear along the slider’s track. (Visible w... |
| `decimalPlaces` | integer |  | 0 | Number of decimal places for marker values |
| `orientation` | enumeration |  | horizontal | The orientation of the slider. If ‘Vertical’, make sure to set the either... |
| `heightUnit` | enumeration |  | percentage |  |
| `height` | integer |  | 100 |  |
| `onChange` | action |  |  |  |

