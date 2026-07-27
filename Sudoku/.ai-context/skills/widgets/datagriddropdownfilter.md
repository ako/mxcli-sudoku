# Drop-down filter

- **Widget ID:** `com.mendix.widget.web.datagriddropdownfilter.DatagridDropdownFilter`
- **Type:** PLUGGABLEWIDGET
- **Version:** 3.4.0

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.datagriddropdownfilter.DatagridDropdownFilter' widget1
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `baseType` | enumeration |  | attr |  |
| `linkedDs` | datasource |  |  |  |
| `attrChoice` | enumeration |  | auto | "Auto" works only when the widget is placed in a Data grid column. |
| `attr` | attribute |  |  |  |
| `auto` | boolean |  | true | Show options based on the references or the enumeration values and captions. |
| `filterOptions` | object |  |  |  |
| `refEntity` | association | Yes |  | Set the entity to enable filtering over association. |
| `refOptions` | datasource |  |  | The options to show in the Drop-down filter widget. |
| `refCaptionSource` | enumeration |  | attr |  |
| `refCaption` | attribute |  |  |  |
| `refCaptionExp` | expression |  |  |  |
| `refSearchAttr` | attribute | Yes |  | Required when Filterable is set to yes |
| `fetchOptionsLazy` | boolean |  | false | Lazy loading enables faster parent loading, but with personalization enabled,... |
| `defaultValue` | expression |  |  | Empty option caption will be shown by default or if configured default value ... |
| `filterable` | boolean |  | false |  |
| `multiSelect` | boolean |  | false |  |
| `emptyOptionCaption` | textTemplate |  |  |  |
| `clearable` | boolean |  | true |  |
| `selectedItemsStyle` | enumeration | Yes | text |  |
| `selectionMethod` | enumeration |  | checkbox |  |
| `valueAttribute` | attribute |  |  | Attribute used to store the last value of the filter. Associations are not su... |
| `onChange` | action |  |  | Action to be triggered when the value or filter changes. |
| `ariaLabel` | textTemplate |  |  | Assistive technology will read this upon reaching the input element. |
| `emptySelectionCaption` | textTemplate |  |  | This text is shown if no options are selected. For example 'Select color' or ... |
| `filterInputPlaceholderCaption` | textTemplate |  |  | This text is shown as placeholder for filterable filters. For example 'Type t... |

