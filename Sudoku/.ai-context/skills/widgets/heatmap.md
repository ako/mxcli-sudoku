# Heat map

- **Widget ID:** `com.mendix.widget.web.heatmap.HeatMap`
- **Type:** PLUGGABLEWIDGET
- **Version:** 6.2.1

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.heatmap.HeatMap' widget1 {
  playground {
    -- widgets for `playground`
  }
  scalecolor item1   -- one entry of `scaleColors`
}
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `seriesDataSource` | datasource | Yes |  |  |
| `seriesValueAttribute` | attribute | Yes |  | The attribute used to display “heat” at an “x y” location. |
| `seriesItemSelection` | selection | Yes |  |  |
| `horizontalAxisAttribute` | attribute |  |  |  |
| `horizontalSortAttribute` | attribute |  |  | Attribute to use for sorting the data. Sorting can only be used when data sou... |
| `horizontalSortOrder` | enumeration | Yes | asc |  |
| `verticalAxisAttribute` | attribute |  |  |  |
| `verticalSortAttribute` | attribute |  |  | Attribute to use for sorting the data. Sorting can only be used when data sou... |
| `verticalSortOrder` | enumeration | Yes | asc |  |
| `enableAdvancedOptions` | boolean | Yes | false |  |
| `showPlaygroundSlot` | boolean | Yes | false |  |
| `playground` | widgets |  |  |  |
| `xAxisLabel` | textTemplate |  |  |  |
| `yAxisLabel` | textTemplate |  |  |  |
| `showScale` | boolean | Yes | false |  |
| `gridLines` | enumeration | Yes | none |  |
| `scaleColors` | object |  |  | The percentages with the colors that should be applied. At least two values n... |
| `smoothColor` | boolean | Yes | false | Gradual color gradient between data points |
| `showValues` | boolean | Yes | false |  |
| `valuesColor` | string |  |  |  |
| `widthUnit` | enumeration | Yes | percentage | Percentage: portion of parent size. Pixels: absolute amount of pixels. |
| `width` | integer | Yes | 100 |  |
| `heightUnit` | enumeration | Yes | percentageOfWidth |  |
| `height` | integer | Yes | 75 |  |
| `onClickAction` | action |  |  |  |
| `tooltipHoverText` | textTemplate |  |  |  |
| `enableThemeConfig` | boolean | Yes | false |  |
| `customLayout` | string |  |  |  |
| `customConfigurations` | string |  |  |  |
| `customSeriesOptions` | string |  |  |  |

## Child Slots (curly-brace blocks)

| MDL keyword | Widget property |
|-------------|----------------|
| `playground` | `playground` |

## Object Lists (repeating child entries)

### `scalecolor` → property `scaleColors`

Item properties:

| Property | Operation |
|----------|-----------|
| `valuePercentage` | primitive |
| `colour` | primitive |

