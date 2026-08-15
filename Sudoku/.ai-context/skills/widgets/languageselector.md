# Language selector

- **Widget ID:** `com.mendix.widget.web.languageselector.LanguageSelector`
- **Type:** PLUGGABLEWIDGET
- **Version:** 1.1.3

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.languageselector.LanguageSelector' widget1
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `languageOptions` | datasource | Yes |  | Recommended: Database data source with System.Language as entity. |
| `languageCaption` | expression | Yes |  | Recommended: $currentObject/Description. |
| `position` | enumeration | Yes | bottom | The location of the menu relative to the current selected language (click area). |
| `trigger` | enumeration | Yes | click |  |
| `hideForSingle` | boolean | Yes | true |  |
| `screenReaderLabelCaption` | textTemplate |  |  | Assistive technology will read this upon reaching the input element. |

