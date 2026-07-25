# Bubble chart

- **Widget ID:** `com.mendix.widget.web.bubblechart.BubbleChart`
- **Type:** PLUGGABLEWIDGET
- **Version:** 6.2.1

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.bubblechart.BubbleChart' widget1 {
  playground {
    -- widgets for `playground`
  }
  line item1   -- one entry of `lines`
}
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `lines` | object |  |  | Add one or more lines. The order influences how lines overlay one another: th... |
| `enableAdvancedOptions` | boolean |  | false |  |
| `showPlaygroundSlot` | boolean |  | false |  |
| `playground` | widgets |  |  |  |
| `xAxisLabel` | textTemplate |  |  |  |
| `yAxisLabel` | textTemplate |  |  |  |
| `showLegend` | boolean |  | true |  |
| `gridLines` | enumeration |  | none |  |
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

### `line` → property `lines`

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
| `staticSizeAttribute` | attribute |
| `dynamicSizeAttribute` | attribute |
| `autosize` | primitive |
| `sizeref` | primitive |
| `staticTooltipHoverText` | texttemplate |
| `dynamicTooltipHoverText` | texttemplate |
| `staticMarkerColor` | expression |
| `dynamicMarkerColor` | expression |
| `staticOnClickAction` | action |
| `dynamicOnClickAction` | action |
| `customSeriesOptions` | primitive |

