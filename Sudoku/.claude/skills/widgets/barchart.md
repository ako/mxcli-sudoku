# Bar chart

- **Widget ID:** `com.mendix.widget.web.barchart.BarChart`
- **Type:** PLUGGABLEWIDGET
- **Version:** 6.2.1

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.barchart.BarChart' widget1 {
  playground {
    -- widgets for `playground`
  }
  series item1   -- one entry of `series`
}
```

## Properties

| Property | Type | Required | Default | Values / notes | Group | Description |
|----------|------|----------|---------|----------------|-------|-------------|
| `series` | object | Yes |  | list; 18 sub-properties below | General::Data source | Add one or more lines. The order influences how lines overlay one another: the first line (from the top) is drawn lowest and other lines are drawn on top of it. |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `dataSet` | enumeration | Yes | static | `static` \| `dynamic` |  | Data set |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `staticDataSource` | datasource |  |  | list |  | Data points for a single line. |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `dynamicDataSource` | datasource |  |  | list |  | Data points for all lines which will be divided into single lines based on the Group by attribute value. |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `groupByAttribute` | attribute |  |  |  |  | Data points within the same group form one line. |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `staticName` | textTemplate |  |  |  |  | The line name displayed in the legend. |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `dynamicName` | textTemplate |  |  |  |  | The line name displayed in the legend. |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `staticXAttribute` | attribute |  |  |  |  | X axis attribute |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `dynamicXAttribute` | attribute |  |  |  |  | X axis attribute |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `staticYAttribute` | attribute |  |  |  |  | Y axis attribute |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `dynamicYAttribute` | attribute |  |  |  |  | Y axis attribute |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `aggregationType` | enumeration | Yes | none | `none` \| `count` \| `sum` \| `avg` \| `min` \| `max` \| `median` \| `mode` \| `first` \| `last` |  | Defines how data is aggregated when multiple Y values are available for a single X value |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `staticTooltipHoverText` | textTemplate |  |  |  |  | Tooltip hover text |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `dynamicTooltipHoverText` | textTemplate |  |  |  |  | Tooltip hover text |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `staticBarColor` | expression |  |  |  |  | Bar color |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `dynamicBarColor` | expression |  |  |  |  | Bar color |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `staticOnClickAction` | action |  |  |  |  | On click action |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `dynamicOnClickAction` | action |  |  |  |  | On click action |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `customSeriesOptions` | string |  |  |  |  | Custom series options |
| `enableAdvancedOptions` | boolean | Yes | false |  | General::General | Enable advanced options |
| `showPlaygroundSlot` | boolean | Yes | false |  | General::General | Show playground slot |
| `playground` | widgets |  |  |  | General::General | Playground slot |
| `xAxisLabel` | textTemplate |  |  |  | General::General | X axis label |
| `yAxisLabel` | textTemplate |  |  |  | General::General | Y axis label |
| `barmode` | enumeration | Yes | group | `group` \| `stack` | General::General | Bar format |
| `showLegend` | boolean | Yes | true |  | General::General | Show legend |
| `gridLines` | enumeration | Yes | none | `none` \| `horizontal` \| `vertical` \| `both` | General::General | Grid lines |
| `widthUnit` | enumeration | Yes | percentage | `percentage` \| `pixels` | Dimensions::Dimensions | Percentage: portion of parent size. Pixels: absolute amount of pixels. |
| `width` | integer | Yes | 100 |  | Dimensions::Dimensions | Width |
| `heightUnit` | enumeration | Yes | percentageOfWidth | `percentageOfWidth` \| `pixels` \| `percentageOfParent` | Dimensions::Dimensions | Height unit |
| `height` | integer | Yes | 75 |  | Dimensions::Dimensions | Height |
| `enableThemeConfig` | boolean | Yes | false |  | Advanced::Advanced | Enable theme folder config loading |
| `customLayout` | string |  |  |  | Advanced::Advanced | Custom layout |
| `customConfigurations` | string |  |  |  | Advanced::Advanced | Custom configurations |

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

---

Regenerated by `mxcli widget docs` and by `refresh catalog`. For the same data live from the `.mpk` — including anything added by a widget upgrade since this file was written — run `mxcli widget describe barchart -p <app.mpr>`.
