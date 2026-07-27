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
| `advanced` | boolean |  | false |  |
| `markers` | object |  |  | A list of static locations on the map. |
| `dynamicMarkers` | object |  |  | A list of markers showing dynamic locations on the map. |
| `apiKey` | string |  |  | API Key for usage of the map through the selected provider.Google Maps - http... |
| `apiKeyExp` | expression |  |  | API Key for usage of the map through the selected provider.Google Maps - http... |
| `geodecodeApiKey` | string |  |  | Used to translate addresses to latitude and longitude. This API Key should be... |
| `geodecodeApiKeyExp` | expression |  |  | Used to translate addresses to latitude and longitude. This API Key should be... |
| `showCurrentLocation` | boolean |  | false | Shows the user current location marker. |
| `optionDrag` | boolean |  | true | The center will move when end-users drag the map. |
| `optionScroll` | boolean |  | true | The map is zoomed with a mouse scroll. |
| `optionZoomControl` | boolean |  | true | Show zoom controls [ + ] [ - ]. |
| `attributionControl` | boolean |  | true | Add attributions to the map (credits). |
| `optionStreetView` | boolean |  | true | Enables the Street View control. |
| `mapTypeControl` | boolean |  | true | Enables switching between different map types. |
| `fullScreenControl` | boolean |  | true |  |
| `rotateControl` | boolean |  | true |  |
| `widthUnit` | enumeration |  | percentage | Percentage: portion of parent size. Pixels: absolute amount of pixels. |
| `width` | integer |  | 100 |  |
| `heightUnit` | enumeration |  | percentageOfWidth |  |
| `height` | integer |  | 75 |  |
| `zoom` | enumeration |  | automatic |  |
| `mapProvider` | enumeration |  | googleMaps |  |
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

