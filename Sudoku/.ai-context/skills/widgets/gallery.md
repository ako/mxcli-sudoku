# Gallery

- **Widget ID:** `com.mendix.widget.web.gallery.Gallery`
- **Type:** PLUGGABLEWIDGET
- **Version:** 3.4.0

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.gallery.Gallery' widget1
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `filtersPlaceholder` | widgets |  |  |  |
| `datasource` | datasource |  |  |  |
| `itemSelection` | selection |  |  |  |
| `itemSelectionMode` | enumeration |  | clear | Defines item selection behavior. |
| `keepSelection` | boolean |  | false | If enabled, selected items will stay selected unless cleared by the user or a... |
| `content` | widgets |  |  |  |
| `refreshIndicator` | boolean |  | false | Show a refresh indicator when the data is being loaded. |
| `desktopItems` | integer |  | 1 |  |
| `tabletItems` | integer |  | 1 |  |
| `phoneItems` | integer |  | 1 |  |
| `pageSize` | integer |  | 20 |  |
| `pagination` | enumeration |  | buttons |  |
| `showTotalCount` | boolean |  | false |  |
| `showPagingButtons` | enumeration |  | always |  |
| `pagingPosition` | enumeration |  | bottom |  |
| `loadMoreButtonCaption` | textTemplate |  |  |  |
| `showEmptyPlaceholder` | enumeration |  | none |  |
| `emptyPlaceholder` | widgets |  |  |  |
| `itemClass` | expression |  |  |  |
| `onClickTrigger` | enumeration |  | single |  |
| `onClick` | action |  |  |  |
| `onSelectionChange` | action |  |  |  |
| `stateStorageType` | enumeration |  | attribute | When Browser local storage is selected, the configuration is scoped to a brow... |
| `stateStorageAttr` | attribute |  |  | Attribute containing the personalized configuration of the capabilities. This... |
| `onConfigurationChange` | action |  |  |  |
| `storeFilters` | boolean |  | true |  |
| `storeSort` | boolean |  | true |  |
| `filterSectionTitle` | textTemplate |  |  | Assistive technology will read this upon reaching a filtering or sorting sect... |
| `emptyMessageTitle` | textTemplate |  |  | Assistive technology will read this upon reaching an empty message section. |
| `ariaLabelListBox` | textTemplate |  |  | Assistive technology will read this upon reaching gallery. |
| `ariaLabelItem` | textTemplate |  |  | Assistive technology will read this upon reaching each gallery item. |
| `selectedCountTemplateSingular` | textTemplate |  |  | Must include '%d' to denote number position ('%d item selected') |
| `selectedCountTemplatePlural` | textTemplate |  |  | Must include '%d' to denote number position ('%d items selected') |

