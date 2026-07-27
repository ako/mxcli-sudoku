# Column chart

- **Widget ID:** `com.mendix.widget.web.columnchart.ColumnChart`
- **Type:** PLUGGABLEWIDGET
- **Version:** 6.2.1

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.columnchart.ColumnChart' widget1 {
  playground {
    -- widgets for `playground`
  }
  series item1   -- one entry of `series`
}
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `series` | object |  |  | Add one or more columns. The order influences how columns overlay one another... |
| `advancedOptions` | boolean |  | false |  |
| `showPlaygroundSlot` | boolean |  | false |  |
| `playground` | widgets |  |  |  |
| `xAxisLabel` | textTemplate |  |  |  |
| `yAxisLabel` | textTemplate |  |  |  |
| `showLegend` | boolean |  | true |  |
| `gridLines` | enumeration |  | none |  |
| `barmode` | enumeration |  | group |  |
| `widthUnit` | enumeration |  | percentage | Percentage: portion of parent size. Pixels: absolute amount of pixels. |
| `width` | integer |  | 100 |  |
| `heightUnit` | enumeration |  | percentageOfWidth |  |
| `height` | integer |  | 75 |  |
| `enableThemeConfig` | boolean |  | false |  |
| `customLayout` | string |  |  |  |
| `customConfigurations` | string |  |  |  |

## Child Slots (curly-brace blocks)

| MDL keyword | Widget property |
|-------------|----------------|
| `playground` | `playground` |

## Object Lists (repeating child entries)

### `series` → property `series`

Item properties:

| Property | Operation |
|----------|-----------|
| `dataSet` | primitive |
| `staticDataSource` | datasource |
| `dynamicDataSource` | datasource |
| `groupByAttribute` | attribute |
| `staticName` | texttemplate |
| `dynamicName` | texttemplate |
| `staticXAttribute` | attribute |
| `dynamicXAttribute` | attribute |
| `staticYAttribute` | attribute |
| `dynamicYAttribute` | attribute |
| `aggregationType` | primitive |
| `staticTooltipHoverText` | texttemplate |
| `dynamicTooltipHoverText` | texttemplate |
| `staticBarColor` | expression |
| `dynamicBarColor` | expression |
| `staticOnClickAction` | action |
| `dynamicOnClickAction` | action |
| `customSeriesOptions` | primitive |

