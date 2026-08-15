# Barcode Scanner

- **Widget ID:** `com.mendix.widget.web.barcodescanner.BarcodeScanner`
- **Type:** PLUGGABLEWIDGET
- **Version:** 2.5.0

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.barcodescanner.BarcodeScanner' widget1
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `datasource` | attribute | Yes |  | The String attribute used to store the result of the scanned barcode. |
| `showMask` | boolean | Yes | true | Apply a mask to camera view, as a specific target area for the barcode. |
| `useAllFormats` | boolean | Yes | true | Scan for all available barcode formats |
| `barcodeFormats` | object | Yes |  |  |
| `onDetect` | action |  |  | Action to trigger when the barcode has been successfully detected. |
| `widthUnit` | enumeration | Yes | percentage | Percentage: portion of parent size. Pixels: absolute amount of pixels. |
| `width` | integer | Yes | 100 |  |
| `heightUnit` | enumeration | Yes | percentageOfWidth |  |
| `height` | integer | Yes | 75 |  |
| `detectionLogic` | enumeration | Yes | native | Choose the detection logic to use for barcode scanning. |

