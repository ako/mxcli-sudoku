# Pie chart

- **Widget ID:** `com.mendix.widget.web.piechart.PieChart`
- **Type:** PLUGGABLEWIDGET
- **Version:** 6.2.1

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.piechart.PieChart' widget1 {
  playground {
    -- widgets for `playground`
  }
}
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `seriesDataSource` | datasource | Yes |  |  |
| `seriesName` | textTemplate | Yes |  |  |
| `seriesValueAttribute` | attribute | Yes |  |  |
| `seriesSortAttribute` | attribute |  |  |  |
| `seriesSortOrder` | enumeration | Yes | asc |  |
| `seriesColorAttribute` | expression |  |  |  |
| `seriesItemSelection` | selection | Yes |  |  |
| `enableAdvancedOptions` | boolean | Yes | false |  |
| `showPlaygroundSlot` | boolean | Yes | false |  |
| `playground` | widgets |  |  |  |
| `showLegend` | boolean | Yes | true |  |
| `holeRadius` | integer | Yes | 0 | A percentage between 0 and 100 indicating the radius of the hole in the pie c... |
| `tooltipHoverText` | textTemplate |  |  |  |
| `widthUnit` | enumeration | Yes | percentage | Percentage: portion of parent size. Pixels: absolute amount of pixels. |
| `width` | integer | Yes | 100 |  |
| `heightUnit` | enumeration | Yes | percentageOfWidth |  |
| `height` | integer | Yes | 75 |  |
| `onClickAction` | action |  |  |  |
| `enableThemeConfig` | boolean | Yes | false |  |
| `customLayout` | string |  |  |  |
| `customConfigurations` | string |  |  |  |
| `customSeriesOptions` | string |  |  |  |

## Child Slots (curly-brace blocks)

| MDL keyword | Widget property |
|-------------|----------------|
| `playground` | `playground` |

