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
| `datasource` | datasource | Yes |  |  |
| `itemSelection` | selection | Yes |  |  |
| `itemSelectionMode` | enumeration | Yes | clear | Defines item selection behavior. |
| `keepSelection` | boolean | Yes | false | If enabled, selected items will stay selected unless cleared by the user or a... |
| `content` | widgets |  |  |  |
| `refreshIndicator` | boolean | Yes | false | Show a refresh indicator when the data is being loaded. |
| `desktopItems` | integer | Yes | 1 |  |
| `tabletItems` | integer | Yes | 1 |  |
| `phoneItems` | integer | Yes | 1 |  |
| `pageSize` | integer | Yes | 20 |  |
| `pagination` | enumeration | Yes | buttons |  |
| `showTotalCount` | boolean | Yes | false |  |
| `showPagingButtons` | enumeration | Yes | always |  |
| `pagingPosition` | enumeration | Yes | bottom |  |
| `loadMoreButtonCaption` | textTemplate |  |  |  |
| `showEmptyPlaceholder` | enumeration | Yes | none |  |
| `emptyPlaceholder` | widgets |  |  |  |
| `itemClass` | expression |  |  |  |
| `onClickTrigger` | enumeration | Yes | single |  |
| `onClick` | action |  |  |  |
| `onSelectionChange` | action |  |  |  |
| `stateStorageType` | enumeration | Yes | attribute | When Browser local storage is selected, the configuration is scoped to a brow... |
| `stateStorageAttr` | attribute |  |  | Attribute containing the personalized configuration of the capabilities. This... |
| `onConfigurationChange` | action |  |  |  |
| `storeFilters` | boolean | Yes | true |  |
| `storeSort` | boolean | Yes | true |  |
| `filterSectionTitle` | textTemplate |  |  | Assistive technology will read this upon reaching a filtering or sorting sect... |
| `emptyMessageTitle` | textTemplate |  |  | Assistive technology will read this upon reaching an empty message section. |
| `ariaLabelListBox` | textTemplate |  |  | Assistive technology will read this upon reaching gallery. |
| `ariaLabelItem` | textTemplate |  |  | Assistive technology will read this upon reaching each gallery item. |
| `selectedCountTemplateSingular` | textTemplate |  |  | Must include '%d' to denote number position ('%d item selected') |
| `selectedCountTemplatePlural` | textTemplate |  |  | Must include '%d' to denote number position ('%d items selected') |

