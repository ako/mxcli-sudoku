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

| Property | Type | Required | Default | Values / notes | Group | Description |
|----------|------|----------|---------|----------------|-------|-------------|
| `advanced` | boolean | Yes | false |  | General::General | Enable advanced options |
| `markers` | object |  |  | list; 8 sub-properties below | General::Markers | A list of static locations on the map. |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `locationType` | enumeration | Yes | address | `address` \| `latlng` |  | Location |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `address` | textTemplate |  |  |  |  | Address containing (a subset of) street, number, zipcode, city and country. |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `latitude` | textTemplate |  |  |  |  | Decimal number from -90.0 to 90.0. |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `longitude` | textTemplate |  |  |  |  | Decimal number from -180.0 to 180.0. |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `title` | textTemplate |  |  |  |  | Title displayed when clicking the marker. |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `onClick` | action |  |  |  |  | On click |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `markerStyle` | enumeration | Yes | default | `default` \| `image` |  | Marker style |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `customMarker` | image |  |  |  |  | Image that replaces the default icon. |
| `dynamicMarkers` | object |  |  | list; 9 sub-properties below | General::Markers | A list of markers showing dynamic locations on the map. |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `markersDS` | datasource |  |  | list |  | Data source |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `locationType` | enumeration | Yes | address | `address` \| `latlng` |  | Location |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `address` | attribute |  |  |  |  | Address containing (a subset of) street, number, zipcode, city and country. |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `latitude` | attribute |  |  |  |  | Decimal number from -90.0 to 90.0. |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `longitude` | attribute |  |  |  |  | Decimal number from -180.0 to 180.0. |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `title` | attribute |  |  |  |  | Title displayed when clicking the marker. |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `onClickAttribute` | action |  |  |  |  | On click |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `markerStyleDynamic` | enumeration | Yes | default | `default` \| `image` |  | Marker style |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `customMarkerDynamic` | image |  |  |  |  | Image that replaces the default icon. |
| `apiKey` | string |  |  |  | General::Configurations | API Key for usage of the map through the selected provider.Google Maps - https://developers.google.com/maps/documentation/javascript/get-api-key Map Box - https://docs.mapbox.com/help/getting-started/access-tokens/ Here Maps - https://developer.here.com/tutorials/getting-here-credentials/ |
| `apiKeyExp` | expression |  |  |  | General::Configurations | API Key for usage of the map through the selected provider.Google Maps - https://developers.google.com/maps/documentation/javascript/get-api-key Map Box - https://docs.mapbox.com/help/getting-started/access-tokens/ Here Maps - https://developer.here.com/tutorials/getting-here-credentials/ |
| `geodecodeApiKey` | string |  |  |  | General::Configurations | Used to translate addresses to latitude and longitude. This API Key should be a Google Geocoding API Key found in https://developers.google.com/maps/documentation/geocoding/overview |
| `geodecodeApiKeyExp` | expression |  |  |  | General::Configurations | Used to translate addresses to latitude and longitude. This API Key should be a Google Geocoding API Key found in https://developers.google.com/maps/documentation/geocoding/overview |
| `showCurrentLocation` | boolean | Yes | false |  | General::Configurations | Shows the user current location marker. |
| `optionDrag` | boolean | Yes | true |  | Controls::General | The center will move when end-users drag the map. |
| `optionScroll` | boolean | Yes | true |  | Controls::General | The map is zoomed with a mouse scroll. |
| `optionZoomControl` | boolean | Yes | true |  | Controls::General | Show zoom controls [ + ] [ - ]. |
| `attributionControl` | boolean | Yes | true |  | Controls::General | Add attributions to the map (credits). |
| `optionStreetView` | boolean | Yes | true |  | Controls::General | Enables the Street View control. |
| `mapTypeControl` | boolean | Yes | true |  | Controls::General | Enables switching between different map types. |
| `fullScreenControl` | boolean | Yes | true |  | Controls::General | Full screen |
| `rotateControl` | boolean | Yes | true |  | Controls::General | Rotate |
| `widthUnit` | enumeration | Yes | percentage | `percentage` \| `pixels` | Dimensions::Dimensions | Percentage: portion of parent size. Pixels: absolute amount of pixels. |
| `width` | integer | Yes | 100 |  | Dimensions::Dimensions | Width |
| `heightUnit` | enumeration | Yes | percentageOfWidth | `percentageOfWidth` \| `pixels` \| `percentageOfParent` | Dimensions::Dimensions | Height unit |
| `height` | integer | Yes | 75 |  | Dimensions::Dimensions | Height |
| `zoom` | enumeration | Yes | automatic | `automatic` \| `world` \| `continent` \| `city` \| `street` \| `buildings` | Dimensions::Dimensions | Zoom level |
| `mapProvider` | enumeration | Yes | googleMaps | `googleMaps` \| `openStreet` \| `mapBox` \| `hereMaps` | Advanced::General | Map provider |
| `googleMapId` | string | Yes |  |  | Advanced::General | Used to render and style the Google map. This MapId key from Google can be found in https://developers.google.com/maps/documentation/get-map-id |

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
| `customMarker` | image |

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
| `customMarkerDynamic` | image |

---

Regenerated by `mxcli widget docs` and by `refresh catalog`. For the same data live from the `.mpk` — including anything added by a widget upgrade since this file was written — run `mxcli widget describe maps -p <app.mpr>`.
