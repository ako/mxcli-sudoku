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
| `series` | object | Yes |  | Add one or more columns. The order influences how columns overlay one another... |
| `advancedOptions` | boolean | Yes | false |  |
| `showPlaygroundSlot` | boolean | Yes | false |  |
| `playground` | widgets |  |  |  |
| `xAxisLabel` | textTemplate |  |  |  |
| `yAxisLabel` | textTemplate |  |  |  |
| `showLegend` | boolean | Yes | true |  |
| `gridLines` | enumeration | Yes | none |  |
| `barmode` | enumeration | Yes | group |  |
| `widthUnit` | enumeration | Yes | percentage | Percentage: portion of parent size. Pixels: absolute amount of pixels. |
| `width` | integer | Yes | 100 |  |
| `heightUnit` | enumeration | Yes | percentageOfWidth |  |
| `height` | integer | Yes | 75 |  |
| `enableThemeConfig` | boolean | Yes | false |  |
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

