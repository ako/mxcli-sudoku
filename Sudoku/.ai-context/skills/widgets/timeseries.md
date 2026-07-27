# Time series

- **Widget ID:** `com.mendix.widget.web.timeseries.TimeSeries`
- **Type:** PLUGGABLEWIDGET
- **Version:** 6.2.1

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.timeseries.TimeSeries' widget1 {
  playground {
    -- widgets for `playground`
  }
  line item1   -- one entry of `lines`
}
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `lines` | object |  |  | Add one or more series. The order of series influences how lines overlay one ... |
| `enableAdvancedOptions` | boolean |  | false |  |
| `showPlaygroundSlot` | boolean |  | false |  |
| `playground` | widgets |  |  |  |
| `xAxisLabel` | textTemplate |  |  |  |
| `yAxisLabel` | textTemplate |  |  |  |
| `showLegend` | boolean |  | true |  |
| `showRangeSlider` | boolean |  | true |  |
| `gridLines` | enumeration |  | none |  |
| `widthUnit` | enumeration |  | percentage | Percentage: portion of parent size. Pixels: absolute amount of pixels. |
| `width` | integer |  | 100 |  |
| `heightUnit` | enumeration |  | percentageOfWidth |  |
| `height` | integer |  | 75 |  |
| `enableThemeConfig` | boolean |  | false |  |
| `customLayout` | string |  |  |  |
| `customConfigurations` | string |  |  |  |
| `yAxisRangeMode` | enumeration |  | tozero | Controls the y-axis range. "From zero" starts the y-axis from zero. "Auto" se... |

## Child Slots (curly-brace blocks)

| MDL keyword | Widget property |
|-------------|----------------|
| `playground` | `playground` |

## Object Lists (repeating child entries)

### `line` → property `lines`

Item properties:

| Property | Operation |
|----------|-----------|
| `dataSet` | primitive |
| `staticDataSource` | datasource |
| `dynamicDataSource` | datasource |
| `staticName` | texttemplate |
| `dynamicName` | texttemplate |
| `groupByAttribute` | attribute |
| `staticXAttribute` | attribute |
| `dynamicXAttribute` | attribute |
| `staticYAttribute` | attribute |
| `dynamicYAttribute` | attribute |
| `aggregationType` | primitive |
| `staticTooltipHoverText` | texttemplate |
| `dynamicTooltipHoverText` | texttemplate |
| `interpolation` | primitive |
| `lineStyle` | primitive |
| `lineColor` | texttemplate |
| `markerColor` | texttemplate |
| `enableFillArea` | primitive |
| `fillColor` | texttemplate |
| `staticOnClickAction` | action |
| `dynamicOnClickAction` | action |
| `customSeriesOptions` | primitive |

