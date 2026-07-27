# Data grid 2

- **Widget ID:** `com.mendix.widget.web.datagrid.Datagrid`
- **Type:** PLUGGABLEWIDGET
- **Version:** 3.4.0

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.datagrid.Datagrid' widget1 {
  emptyplaceholder {
    -- widgets for `emptyPlaceholder`
  }
  controlbar {
    -- widgets for `filtersPlaceholder`
  }
  column item1   -- one entry of `columns`
}
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `advanced` | boolean |  | false |  |
| `datasource` | datasource |  |  |  |
| `refreshInterval` | integer |  | 0 |  |
| `itemSelection` | selection |  |  |  |
| `itemSelectionMethod` | enumeration |  | checkbox |  |
| `itemSelectionMode` | enumeration |  | clear | Defines item selection behavior. |
| `showSelectAllToggle` | boolean |  | true | Show a checkbox in the grid header to check or uncheck multiple items. |
| `keepSelection` | boolean |  | false | If enabled, selected items will stay selected unless cleared by the user or a... |
| `loadingType` | enumeration | Yes | spinner |  |
| `refreshIndicator` | boolean |  | false | Show a refresh indicator when the data is being loaded. |
| `columns` | object |  |  |  |
| `columnsFilterable` | boolean |  | true |  |
| `pageSize` | integer |  | 20 |  |
| `pagination` | enumeration |  | buttons |  |
| `showPagingButtons` | enumeration |  | always |  |
| `showNumberOfRows` | boolean |  | false |  |
| `pagingPosition` | enumeration |  | bottom |  |
| `loadMoreButtonCaption` | textTemplate |  |  |  |
| `showEmptyPlaceholder` | enumeration |  | none |  |
| `emptyPlaceholder` | widgets |  |  |  |
| `rowClass` | expression |  |  |  |
| `onClickTrigger` | enumeration |  | single |  |
| `onClick` | action |  |  |  |
| `onSelectionChange` | action |  |  |  |
| `filtersPlaceholder` | widgets |  |  |  |
| `columnsSortable` | boolean |  | true | Enable sorting for all columns unless specified otherwise in the column setting |
| `columnsResizable` | boolean |  | true | Enable resizing for all columns unless specified otherwise in the column setting |
| `columnsDraggable` | boolean |  | true | Enable reordering for all columns unless specified otherwise in the column se... |
| `columnsHidable` | boolean |  | true | Enable hiding for all columns unless specified otherwise in the column setting |
| `configurationStorageType` | enumeration |  | attribute | When Browser local storage is selected, the configuration is scoped to a brow... |
| `configurationAttribute` | attribute |  |  | Attribute containing the personalized configuration of the capabilities. This... |
| `storeFiltersInPersonalization` | boolean |  | true |  |
| `onConfigurationChange` | action |  |  |  |
| `filterSectionTitle` | textTemplate |  |  | Assistive technology will read this upon reaching a filtering or sorting sect... |
| `exportDialogLabel` | textTemplate |  |  | Assistive technology will read this upon reaching a export dialog. |
| `cancelExportLabel` | textTemplate |  |  | Assistive technology will read this upon reaching a cancel button. |
| `selectRowLabel` | textTemplate |  |  | If selection is enabled, assistive technology will read this upon reaching a ... |
| `selectAllRowsLabel` | textTemplate |  |  | If selection is enabled, assistive technology will read this upon reaching 'S... |
| `selectedCountTemplateSingular` | textTemplate |  |  | Must include '%d' to denote number position ('%d row selected') |
| `selectedCountTemplatePlural` | textTemplate |  |  | Must include '%d' to denote number position ('%d rows selected') |

## Child Slots (curly-brace blocks)

| MDL keyword | Widget property |
|-------------|----------------|
| `emptyplaceholder` | `emptyPlaceholder` |
| `controlbar` | `filtersPlaceholder` |

## Object Lists (repeating child entries)

### `column` → property `columns`

Item properties:

| Property | Operation |
|----------|-----------|
| `showContentAs` | primitive |
| `attribute` | attribute |
| `dynamicText` | texttemplate |
| `exportValue` | texttemplate |
| `header` | texttemplate |
| `tooltip` | texttemplate |
| `visible` | expression |
| `sortable` | primitive |
| `resizable` | primitive |
| `draggable` | primitive |
| `hidable` | primitive |
| `allowEventPropagation` | primitive |
| `width` | primitive |
| `minWidth` | primitive |
| `minWidthLimit` | primitive |
| `size` | primitive |
| `alignment` | primitive |
| `columnClass` | expression |
| `wrapText` | primitive |

Item child slots:

| MDL keyword | Widget property |
|-------------|----------------|
| `content` | `content` |
| `filter` | `filter` |

