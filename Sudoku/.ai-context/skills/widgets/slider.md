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
| `valueAttribute` | attribute | Yes |  |  |
| `advanced` | boolean | Yes | false |  |
| `minValueType` | enumeration | Yes | static |  |
| `staticMinimumValue` | decimal | Yes | 0 | The minimum value of the slider. |
| `minAttribute` | attribute |  |  | The minimum value of the slider. |
| `expressionMinimumValue` | expression |  |  | The minimum value of the slider. |
| `maxValueType` | enumeration | Yes | static |  |
| `staticMaximumValue` | decimal | Yes | 100 | The maximum value of the slider. |
| `maxAttribute` | attribute |  |  | The maximum value of the slider. |
| `expressionMaximumValue` | expression |  |  | The maximum value of the slider. |
| `stepSizeType` | enumeration | Yes | static |  |
| `stepValue` | decimal | Yes | 1 | Value to be added or subtracted on each step the slider makes. Must be greate... |
| `stepAttribute` | attribute |  |  | Value to be added or subtracted on each step the slider makes. Must be greate... |
| `expressionStepSize` | expression |  |  | Value to be added or subtracted on each step the slider makes. Must be greate... |
| `showTooltip` | boolean | Yes | true |  |
| `tooltipType` | enumeration | Yes | value | By default tooltip shows current value. Choose 'Custom' to create your own te... |
| `tooltip` | textTemplate |  |  |  |
| `tooltipAlwaysVisible` | boolean | Yes | false | When enabled tooltip is always visible to the user |
| `noOfMarkers` | integer | Yes | 2 | The number of marker ticks that appear along the slider’s track. (Visible w... |
| `decimalPlaces` | integer | Yes | 0 | Number of decimal places for marker values |
| `orientation` | enumeration | Yes | horizontal | The orientation of the slider. If ‘Vertical’, make sure to set the either... |
| `heightUnit` | enumeration | Yes | percentage |  |
| `height` | integer | Yes | 100 |  |
| `onChange` | action |  |  |  |

