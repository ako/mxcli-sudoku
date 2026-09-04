# Combo box

- **Widget ID:** `com.mendix.widget.web.combobox.Combobox`
- **Type:** PLUGGABLEWIDGET
- **Version:** 2.5.0

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.combobox.Combobox' widget1
```

## Properties

| Property | Type | Required | Default | Values / notes | Group | Description |
|----------|------|----------|---------|----------------|-------|-------------|
| `source` | enumeration | Yes | context | `context` \| `database` \| `static` | General::Data source | Source |
| `optionsSourceType` | enumeration | Yes | association | `association` \| `enumeration` \| `boolean` | General::Data source | Type |
| `attributeEnumeration` | attribute | Yes |  |  | General::Data source | Attribute |
| `attributeBoolean` | attribute | Yes |  |  | General::Data source | Attribute |
| `optionsSourceDatabaseDataSource` | datasource |  |  | list | General::Data source | Selectable objects |
| `optionsSourceDatabaseItemSelection` | selection | Yes |  | on change → `onChangeDatabaseEvent` | General::Data source | Selection type |
| `optionsSourceAssociationCaptionType` | enumeration | Yes | attribute | `attribute` \| `expression` | General::Caption | Caption type |
| `optionsSourceDatabaseCaptionType` | enumeration | Yes | attribute | `attribute` \| `expression` | General::Caption | Caption type |
| `optionsSourceAssociationCaptionAttribute` | attribute | Yes |  |  | General::Caption | Caption |
| `optionsSourceDatabaseCaptionAttribute` | attribute | Yes |  |  | General::Caption | Caption |
| `optionsSourceAssociationCaptionExpression` | expression | Yes |  |  | General::Caption | Caption |
| `optionsSourceDatabaseCaptionExpression` | expression | Yes |  |  | General::Caption | Caption |
| `optionsSourceDatabaseValueAttribute` | attribute | Yes |  |  | General::Store value | Value |
| `databaseAttributeString` | attribute |  |  |  | General::Store value | Target attribute |
| `attributeAssociation` | association | Yes |  |  | General::Attribute | Entity |
| `optionsSourceAssociationDataSource` | datasource |  |  | list | General::Attribute | Selectable objects |
| `staticAttribute` | attribute | Yes |  |  | General::Values | Attribute |
| `optionsSourceStaticDataSource` | object | Yes |  | list; 3 sub-properties below | General::Values | Values |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `staticDataSourceValue` | expression | Yes |  |  |  | Value to be set |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `staticDataSourceCustomContent` | widgets | Yes |  |  |  | Custom content |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `staticDataSourceCaption` | textTemplate | Yes |  |  |  | Caption to be shown |
| `emptyOptionText` | textTemplate |  |  |  | General::General | Placeholder text |
| `noOptionsText` | textTemplate |  |  |  | General::General | No options text |
| `clearable` | boolean | Yes | true |  | General::General | Clearable |
| `optionsSourceAssociationCustomContentType` | enumeration | Yes | no | `yes` \| `listItem` \| `no` | General::General | Custom content |
| `optionsSourceAssociationCustomContent` | widgets | Yes |  |  | General::General | Custom content |
| `optionsSourceDatabaseCustomContentType` | enumeration | Yes | no | `yes` \| `listItem` \| `no` | General::General | Custom content |
| `optionsSourceDatabaseCustomContent` | widgets | Yes |  |  | General::General | Custom content |
| `staticDataSourceCustomContentType` | enumeration | Yes | no | `yes` \| `listItem` \| `no` | General::General | Custom content |
| `showFooter` | boolean | Yes | false |  | General::General | Show footer |
| `menuFooterContent` | widgets |  |  |  | General::General | Footer content |
| `selectionMethod` | enumeration | Yes | checkbox | `checkbox` \| `rowclick` | General::Multiple-selection (reference set) | Selection method |
| `selectedItemsStyle` | enumeration | Yes | text | `text` \| `boxes` | General::Multiple-selection (reference set) | Show selected items as |
| `selectAllButton` | boolean | Yes | false |  | General::Multiple-selection (reference set) | Add a button to select/deselect all options. |
| `selectAllButtonCaption` | textTemplate | Yes |  |  | General::Multiple-selection (reference set) | Caption for select all |
| `customEditability` | enumeration | Yes | default | `default` \| `never` \| `conditionally` | General::Editability | Editable |
| `customEditabilityExpression` | expression | Yes | false |  | General::Editability | Condition |
| `readOnlyStyle` | enumeration | Yes | text | `bordered` \| `text` | General::Editability | How the combo box will appear in read-only mode. |
| `onChangeEvent` | action |  |  |  | Events | On change |
| `onChangeDatabaseEvent` | action |  |  |  | Events | On change |
| `onEnterEvent` | action |  |  |  | Events | On enter |
| `onLeaveEvent` | action |  |  |  | Events | On leave |
| `onChangeFilterInputEvent` | action |  |  |  | Events | On filter input change |
| `filterInputDebounceInterval` | integer | Yes | 200 |  | Events | The debounce interval for each filter input change event triggered in milliseconds. |
| `ariaRequired` | expression | Yes | false |  | Accessibility::Accessibility | Aria required |
| `ariaLabel` | textTemplate |  |  |  | Accessibility::Aria labels | Used to describe the combo box. |
| `clearButtonAriaLabel` | textTemplate |  |  |  | Accessibility::Aria labels | Used to clear all selected values. |
| `removeValueAriaLabel` | textTemplate |  |  |  | Accessibility::Aria labels | Used to remove individual selected values when using labels with multi-selection. |
| `a11ySelectedValue` | textTemplate |  |  |  | Accessibility::Accessibility status message | Output example: "Selected value: Avocado, Apple, Banana." |
| `a11yOptionsAvailable` | textTemplate |  |  |  | Accessibility::Accessibility status message | Output example: "Number of options available: 1" |
| `a11yInstructions` | textTemplate |  |  |  | Accessibility::Accessibility status message | Instructions to be read after announcing the status. |
| `lazyLoading` | boolean | Yes | true |  | Advanced::Performance | Lazy loading |
| `loadingType` | enumeration | Yes | spinner | `spinner` \| `skeleton` | Advanced::Performance | Loading type |
| `selectedItemsSorting` | enumeration | Yes | none | `caption` \| `none` | Advanced::Multiple-selection | How selected items should be sorted. |
| `filterType` | enumeration | Yes | contains | `contains` \| `containsExact` \| `startsWith` \| `none` | Advanced::Filter | Filter type |

---

Regenerated by `mxcli widget docs` and by `refresh catalog`. For the same data live from the `.mpk` — including anything added by a widget upgrade since this file was written — run `mxcli widget describe combobox -p <app.mpr>`.
