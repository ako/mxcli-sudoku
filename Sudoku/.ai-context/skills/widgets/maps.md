# Maps

- **Widget ID:** `com.mendix.widget.custom.Maps.Maps`
- **Type:** PLUGGABLEWIDGET
- **Version:** 4.0.0

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.custom.Maps.Maps' widget1 {
  marker item1   -- one entry of `markers`
  dynamicmarker item1   -- one entry of `dynamicMarkers`
}
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `advanced` | boolean | Yes | false |  |
| `markers` | object |  |  | A list of static locations on the map. |
| `dynamicMarkers` | object |  |  | A list of markers showing dynamic locations on the map. |
| `apiKey` | string |  |  | API Key for usage of the map through the selected provider.Google Maps - http... |
| `apiKeyExp` | expression |  |  | API Key for usage of the map through the selected provider.Google Maps - http... |
| `geodecodeApiKey` | string |  |  | Used to translate addresses to latitude and longitude. This API Key should be... |
| `geodecodeApiKeyExp` | expression |  |  | Used to translate addresses to latitude and longitude. This API Key should be... |
| `showCurrentLocation` | boolean | Yes | false | Shows the user current location marker. |
| `optionDrag` | boolean | Yes | true | The center will move when end-users drag the map. |
| `optionScroll` | boolean | Yes | true | The map is zoomed with a mouse scroll. |
| `optionZoomControl` | boolean | Yes | true | Show zoom controls [ + ] [ - ]. |
| `attributionControl` | boolean | Yes | true | Add attributions to the map (credits). |
| `optionStreetView` | boolean | Yes | true | Enables the Street View control. |
| `mapTypeControl` | boolean | Yes | true | Enables switching between different map types. |
| `fullScreenControl` | boolean | Yes | true |  |
| `rotateControl` | boolean | Yes | true |  |
| `widthUnit` | enumeration | Yes | percentage | Percentage: portion of parent size. Pixels: absolute amount of pixels. |
| `width` | integer | Yes | 100 |  |
| `heightUnit` | enumeration | Yes | percentageOfWidth |  |
| `height` | integer | Yes | 75 |  |
| `zoom` | enumeration | Yes | automatic |  |
| `mapProvider` | enumeration | Yes | googleMaps |  |
| `googleMapId` | string | Yes |  | Used to render and style the Google map. This MapId key from Google can be fo... |

## Object Lists (repeating child entries)

### `marker` → property `markers`

Item properties:

| Property | Operation |
|----------|-----------|
| `locationType` | primitive |
| `address` | texttemplate |
| `latitude` | texttemplate |
| `longitude` | texttemplate |
| `title` | texttemplate |
| `onClick` | action |
| `markerStyle` | primitive |

### `dynamicmarker` → property `dynamicMarkers`

Item properties:

| Property | Operation |
|----------|-----------|
| `markersDS` | datasource |
| `locationType` | primitive |
| `address` | attribute |
| `latitude` | attribute |
| `longitude` | attribute |
| `title` | attribute |
| `onClickAttribute` | action |
| `markerStyleDynamic` | primitive |

