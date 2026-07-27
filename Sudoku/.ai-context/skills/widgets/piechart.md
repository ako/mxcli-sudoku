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
| `seriesSortOrder` | enumeration |  | asc |  |
| `seriesColorAttribute` | expression |  |  |  |
| `seriesItemSelection` | selection |  |  |  |
| `enableAdvancedOptions` | boolean |  | false |  |
| `showPlaygroundSlot` | boolean |  | false |  |
| `playground` | widgets |  |  |  |
| `showLegend` | boolean |  | true |  |
| `holeRadius` | integer |  | 0 | A percentage between 0 and 100 indicating the radius of the hole in the pie c... |
| `tooltipHoverText` | textTemplate |  |  |  |
| `widthUnit` | enumeration |  | percentage | Percentage: portion of parent size. Pixels: absolute amount of pixels. |
| `width` | integer |  | 100 |  |
| `heightUnit` | enumeration |  | percentageOfWidth |  |
| `height` | integer |  | 75 |  |
| `onClickAction` | action |  |  |  |
| `enableThemeConfig` | boolean |  | false |  |
| `customLayout` | string |  |  |  |
| `customConfigurations` | string |  |  |  |
| `customSeriesOptions` | string |  |  |  |

## Child Slots (curly-brace blocks)

| MDL keyword | Widget property |
|-------------|----------------|
| `playground` | `playground` |

