# Pop-up menu

- **Widget ID:** `com.mendix.widget.web.popupmenu.PopupMenu`
- **Type:** PLUGGABLEWIDGET
- **Version:** 4.0.2

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.popupmenu.PopupMenu' widget1 {
  menutrigger {
    -- widgets for `menuTrigger`
  }
  item item1   -- one entry of `basicItems`
  customitem item1   -- one entry of `customItems`
}
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `advancedMode` | boolean | Yes | false |  |
| `menuTrigger` | widgets | Yes |  | Responsible for toggling the Pop-up menu. |
| `basicItems` | object |  |  | The popup menu items. |
| `customItems` | object |  |  | The popup menu custom items. To make sure the popup closes correctly after a ... |
| `trigger` | enumeration | Yes | onclick |  |
| `hoverCloseOn` | enumeration | Yes | onHoverLeave |  |
| `position` | enumeration | Yes | bottom | The location of the menu relative to the click area. |
| `clippingStrategy` | enumeration | Yes | absolute | 'Absolute' positions the floating element relative to its nearest positioned ... |
| `menuToggle` | boolean | Yes | false | Use this to see a preview of the menu items while developing. |

## Child Slots (curly-brace blocks)

| MDL keyword | Widget property |
|-------------|----------------|
| `menutrigger` | `menuTrigger` |

## Object Lists (repeating child entries)

### `item` → property `basicItems`

Item properties:

| Property | Operation |
|----------|-----------|
| `itemType` | primitive |
| `caption` | texttemplate |
| `visible` | expression |
| `action` | action |
| `styleClass` | primitive |

### `customitem` → property `customItems`

Item properties:

| Property | Operation |
|----------|-----------|
| `visible` | expression |
| `action` | action |

Item child slots:

| MDL keyword | Widget property |
|-------------|----------------|
| `content` | `content` |

