# Fieldset

- **Widget ID:** `com.mendix.widget.web.fieldset.Fieldset`
- **Type:** PLUGGABLEWIDGET
- **Version:** 3.2.1

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.fieldset.Fieldset' widget1 {
  template {
    -- widgets for `content`
  }
}
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `legend` | textTemplate |  |  |  |
| `content` | widgets | Yes |  |  |

## Child Slots (curly-brace blocks)

| MDL keyword | Widget property |
|-------------|----------------|
| `template` | `content` |

