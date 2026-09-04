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

| Property | Type | Required | Default | Values / notes | Group | Description |
|----------|------|----------|---------|----------------|-------|-------------|
| `advanced` | boolean | Yes | false |  | General::General | Enable advanced options |
| `datasource` | datasource | Yes |  | list | General::General | Data source |
| `refreshInterval` | integer | Yes | 0 |  | General::General | Refresh time (in seconds) |
| `itemSelection` | selection | Yes |  |  | General::General | Selection |
| `itemSelectionMethod` | enumeration | Yes | checkbox | `checkbox` \| `rowClick` | General::General | Selection method |
| `itemSelectionMode` | enumeration | Yes | clear | `toggle` \| `clear` | General::General | Defines item selection behavior. |
| `showSelectAllToggle` | boolean | Yes | true |  | General::General | Show a checkbox in the grid header to check or uncheck multiple items. |
| `keepSelection` | boolean | Yes | false |  | General::General | If enabled, selected items will stay selected unless cleared by the user or a Nanoflow. |
| `loadingType` | enumeration | Yes | spinner | `spinner` \| `skeleton` | General::General | Loading type |
| `refreshIndicator` | boolean | Yes | false |  | General::General | Show a refresh indicator when the data is being loaded. |
| `columns` | object | Yes |  | list; 21 sub-properties below | General::Columns | Columns |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `showContentAs` | enumeration | Yes | attribute | `attribute` \| `dynamicText` \| `customContent` |  | Show |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `attribute` | attribute |  |  |  |  | Attribute is required if the column can be sorted or filtered |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `content` | widgets |  |  |  |  | Custom content |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `dynamicText` | textTemplate |  |  |  |  | Dynamic text |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `exportValue` | textTemplate |  |  |  |  | Export value |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `header` | textTemplate |  |  |  |  | Caption |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `tooltip` | textTemplate |  |  |  |  | Tooltip |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `filter` | widgets |  |  |  |  | Filter |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `visible` | expression | Yes | true |  |  | Visible |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `sortable` | boolean | Yes | true |  |  | Can sort |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `resizable` | boolean | Yes | true |  |  | Can resize |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `draggable` | boolean | Yes | true |  |  | Can reorder |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `hidable` | enumeration | Yes | yes | `yes` \| `hidden` \| `no` |  | Can hide |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `allowEventPropagation` | boolean | Yes | true |  |  | If set to yes, then all default events on the row, such as "on click" or selection, will be triggered when the user interacts with custom content. |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `width` | enumeration | Yes | autoFill | `autoFill` \| `autoFit` \| `manual` |  | Column width |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `minWidth` | enumeration | Yes | auto | `auto` \| `minContent` \| `manual` |  | Min width |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `minWidthLimit` | integer | Yes | 100 |  |  | Min width value (px) |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `size` | integer | Yes | 1 |  |  | Column size |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `alignment` | enumeration | Yes | left | `left` \| `center` \| `right` |  | Alignment |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `columnClass` | expression |  |  |  |  | Dynamic cell class |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `wrapText` | boolean | Yes | false |  |  | Wrap text |
| `columnsFilterable` | boolean | Yes | true |  | General::Columns | Show column filters |
| `pageSize` | integer | Yes | 20 |  | General::Rows | Page size |
| `pagination` | enumeration | Yes | buttons | `buttons` \| `virtualScrolling` \| `loadMore` | General::Rows | Pagination |
| `showPagingButtons` | enumeration | Yes | always | `always` \| `auto` | General::Rows | Show paging buttons |
| `showNumberOfRows` | boolean | Yes | false |  | General::Rows | Show number of rows |
| `pagingPosition` | enumeration | Yes | bottom | `bottom` \| `top` \| `both` | General::Rows | Position of pagination |
| `loadMoreButtonCaption` | textTemplate |  |  |  | General::Rows | Load more caption |
| `showEmptyPlaceholder` | enumeration | Yes | none | `none` \| `custom` | General::Rows | Empty list message |
| `emptyPlaceholder` | widgets |  |  |  | General::Rows | Empty placeholder |
| `rowClass` | expression |  |  |  | General::Rows | Dynamic row class |
| `onClickTrigger` | enumeration | Yes | single | `single` \| `double` | General::Events | On click trigger |
| `onClick` | action |  |  |  | General::Events | On click action |
| `onSelectionChange` | action |  |  |  | General::Events | On selection change |
| `filtersPlaceholder` | widgets |  |  |  | General::Events | Filters placeholder |
| `columnsSortable` | boolean | Yes | true |  | Personalization::Column capabilities | Enable sorting for all columns unless specified otherwise in the column setting |
| `columnsResizable` | boolean | Yes | true |  | Personalization::Column capabilities | Enable resizing for all columns unless specified otherwise in the column setting |
| `columnsDraggable` | boolean | Yes | true |  | Personalization::Column capabilities | Enable reordering for all columns unless specified otherwise in the column setting |
| `columnsHidable` | boolean | Yes | true |  | Personalization::Column capabilities | Enable hiding for all columns unless specified otherwise in the column setting |
| `configurationStorageType` | enumeration | Yes | attribute | `attribute` \| `localStorage` | Personalization::Configuration | When Browser local storage is selected, the configuration is scoped to a browser profile. This configuration is not tied to a Mendix user. |
| `configurationAttribute` | attribute |  |  | on change → `onConfigurationChange` | Personalization::Configuration | Attribute containing the personalized configuration of the capabilities. This configuration is automatically stored and loaded. The attribute requires Unlimited String. |
| `storeFiltersInPersonalization` | boolean | Yes | true |  | Personalization::Configuration | Store filters |
| `onConfigurationChange` | action |  |  |  | Personalization::Configuration | On change |
| `filterSectionTitle` | textTemplate |  |  |  | Accessibility::Aria labels | Assistive technology will read this upon reaching a filtering or sorting section. |
| `exportDialogLabel` | textTemplate |  |  |  | Accessibility::Aria labels | Assistive technology will read this upon reaching a export dialog. |
| `cancelExportLabel` | textTemplate |  |  |  | Accessibility::Aria labels | Assistive technology will read this upon reaching a cancel button. |
| `selectRowLabel` | textTemplate |  |  |  | Accessibility::Aria labels | If selection is enabled, assistive technology will read this upon reaching a checkbox. |
| `selectAllRowsLabel` | textTemplate |  |  |  | Accessibility::Aria labels | If selection is enabled, assistive technology will read this upon reaching 'Select all' checkbox. |
| `selectedCountTemplateSingular` | textTemplate |  |  |  | Accessibility::Aria labels | Must include '%d' to denote number position ('%d row selected') |
| `selectedCountTemplatePlural` | textTemplate |  |  |  | Accessibility::Aria labels | Must include '%d' to denote number position ('%d rows selected') |

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

---

Regenerated by `mxcli widget docs` and by `refresh catalog`. For the same data live from the `.mpk` — including anything added by a widget upgrade since this file was written — run `mxcli widget describe datagrid -p <app.mpr>`.
