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
| `lines` | object | Yes |  | Add one or more series. The order of series influences how lines overlay one ... |
| `enableAdvancedOptions` | boolean | Yes | false |  |
| `showPlaygroundSlot` | boolean | Yes | false |  |
| `playground` | widgets |  |  |  |
| `xAxisLabel` | textTemplate |  |  |  |
| `yAxisLabel` | textTemplate |  |  |  |
| `showLegend` | boolean | Yes | true |  |
| `showRangeSlider` | boolean | Yes | true |  |
| `gridLines` | enumeration | Yes | none |  |
| `widthUnit` | enumeration | Yes | percentage | Percentage: portion of parent size. Pixels: absolute amount of pixels. |
| `width` | integer | Yes | 100 |  |
| `heightUnit` | enumeration | Yes | percentageOfWidth |  |
| `height` | integer | Yes | 75 |  |
| `enableThemeConfig` | boolean | Yes | false |  |
| `customLayout` | string |  |  |  |
| `customConfigurations` | string |  |  |  |
| `yAxisRangeMode` | enumeration | Yes | tozero | Controls the y-axis range. "From zero" starts the y-axis from zero. "Auto" se... |

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

