# HTML Element

- **Widget ID:** `com.mendix.widget.web.htmlelement.HTMLElement`
- **Type:** PLUGGABLEWIDGET
- **Version:** 1.2.2

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.htmlelement.HTMLElement' widget1 {
  tagcontentcontainer {
    -- widgets for `tagContentContainer`
  }
  tagcontentrepeatcontainer {
    -- widgets for `tagContentRepeatContainer`
  }
  attribute item1   -- one entry of `attributes`
  event item1   -- one entry of `events`
}
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `tagName` | enumeration | Yes | div |  |
| `tagNameCustom` | string |  | div |  |
| `tagUseRepeat` | boolean | Yes | false | Repeat element for each item in data source. |
| `tagContentRepeatDataSource` | datasource | Yes |  |  |
| `tagContentMode` | enumeration | Yes | container |  |
| `tagContentHTML` | textTemplate |  |  |  |
| `tagContentContainer` | widgets |  |  |  |
| `tagContentRepeatHTML` | textTemplate |  |  |  |
| `tagContentRepeatContainer` | widgets |  |  |  |
| `attributes` | object |  |  | The HTML attributes that are added to the HTML element. For example: ‘title... |
| `events` | object |  |  |  |
| `sanitizationConfigFull` | string |  |  | Configuration for HTML sanitization in JSON format. Leave blank for default. |

## Child Slots (curly-brace blocks)

| MDL keyword | Widget property |
|-------------|----------------|
| `tagcontentcontainer` | `tagContentContainer` |
| `tagcontentrepeatcontainer` | `tagContentRepeatContainer` |

## Object Lists (repeating child entries)

### `attribute` → property `attributes`

Item properties:

| Property | Operation |
|----------|-----------|
| `attributeName` | primitive |
| `attributeValueType` | primitive |
| `attributeValueTemplate` | texttemplate |
| `attributeValueExpression` | expression |
| `attributeValueTemplateRepeat` | texttemplate |
| `attributeValueExpressionRepeat` | expression |

### `event` → property `events`

Item properties:

| Property | Operation |
|----------|-----------|
| `eventName` | primitive |
| `eventAction` | action |
| `eventActionRepeat` | action |
| `eventStopPropagation` | primitive |
| `eventPreventDefault` | primitive |

