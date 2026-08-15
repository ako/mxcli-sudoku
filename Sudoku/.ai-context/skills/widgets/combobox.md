# Combo box

- **Widget ID:** `com.mendix.widget.web.combobox.Combobox`
- **Type:** PLUGGABLEWIDGET
- **Version:** 2.5.0

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.combobox.Combobox' widget1
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `source` | enumeration | Yes | context |  |
| `optionsSourceType` | enumeration | Yes | association |  |
| `attributeEnumeration` | attribute | Yes |  |  |
| `attributeBoolean` | attribute | Yes |  |  |
| `optionsSourceDatabaseDataSource` | datasource |  |  |  |
| `optionsSourceDatabaseItemSelection` | selection | Yes |  |  |
| `optionsSourceAssociationCaptionType` | enumeration | Yes | attribute |  |
| `optionsSourceDatabaseCaptionType` | enumeration | Yes | attribute |  |
| `optionsSourceAssociationCaptionAttribute` | attribute | Yes |  |  |
| `optionsSourceDatabaseCaptionAttribute` | attribute | Yes |  |  |
| `optionsSourceAssociationCaptionExpression` | expression | Yes |  |  |
| `optionsSourceDatabaseCaptionExpression` | expression | Yes |  |  |
| `optionsSourceDatabaseValueAttribute` | attribute | Yes |  |  |
| `databaseAttributeString` | attribute |  |  |  |
| `attributeAssociation` | association | Yes |  |  |
| `optionsSourceAssociationDataSource` | datasource |  |  |  |
| `staticAttribute` | attribute | Yes |  |  |
| `optionsSourceStaticDataSource` | object | Yes |  |  |
| `emptyOptionText` | textTemplate |  |  |  |
| `noOptionsText` | textTemplate |  |  |  |
| `clearable` | boolean | Yes | true |  |
| `optionsSourceAssociationCustomContentType` | enumeration | Yes | no |  |
| `optionsSourceAssociationCustomContent` | widgets | Yes |  |  |
| `optionsSourceDatabaseCustomContentType` | enumeration | Yes | no |  |
| `optionsSourceDatabaseCustomContent` | widgets | Yes |  |  |
| `staticDataSourceCustomContentType` | enumeration | Yes | no |  |
| `showFooter` | boolean | Yes | false |  |
| `menuFooterContent` | widgets |  |  |  |
| `selectionMethod` | enumeration | Yes | checkbox |  |
| `selectedItemsStyle` | enumeration | Yes | text |  |
| `selectAllButton` | boolean | Yes | false | Add a button to select/deselect all options. |
| `selectAllButtonCaption` | textTemplate | Yes |  |  |
| `customEditability` | enumeration | Yes | default |  |
| `customEditabilityExpression` | expression | Yes | false |  |
| `readOnlyStyle` | enumeration | Yes | text | How the combo box will appear in read-only mode. |
| `onChangeEvent` | action |  |  |  |
| `onChangeDatabaseEvent` | action |  |  |  |
| `onEnterEvent` | action |  |  |  |
| `onLeaveEvent` | action |  |  |  |
| `onChangeFilterInputEvent` | action |  |  |  |
| `filterInputDebounceInterval` | integer | Yes | 200 | The debounce interval for each filter input change event triggered in millise... |
| `ariaRequired` | expression | Yes | false |  |
| `ariaLabel` | textTemplate |  |  | Used to describe the combo box. |
| `clearButtonAriaLabel` | textTemplate |  |  | Used to clear all selected values. |
| `removeValueAriaLabel` | textTemplate |  |  | Used to remove individual selected values when using labels with multi-select... |
| `a11ySelectedValue` | textTemplate |  |  | Output example: "Selected value: Avocado, Apple, Banana." |
| `a11yOptionsAvailable` | textTemplate |  |  | Output example: "Number of options available: 1" |
| `a11yInstructions` | textTemplate |  |  | Instructions to be read after announcing the status. |
| `lazyLoading` | boolean | Yes | true |  |
| `loadingType` | enumeration | Yes | spinner |  |
| `selectedItemsSorting` | enumeration | Yes | none | How selected items should be sorted. |
| `filterType` | enumeration | Yes | contains |  |

