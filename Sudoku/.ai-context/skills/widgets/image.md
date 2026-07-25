# Image

- **Widget ID:** `com.mendix.widget.web.image.Image`
- **Type:** PLUGGABLEWIDGET
- **Version:** 1.5.0

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.image.Image' widget1
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `datasource` | enumeration |  | image |  |
| `imageObject` | image |  |  |  |
| `defaultImageDynamic` | image |  |  | This is the image that is displayed if no image is uploaded. |
| `imageUrl` | textTemplate |  |  | The link of the external image. |
| `imageIcon` | icon |  |  | The icon image. |
| `isBackgroundImage` | boolean |  | false | Whether the image is rendered as a background. More content can be put inside... |
| `children` | widgets |  |  |  |
| `onClickType` | enumeration |  | action |  |
| `onClick` | action |  |  |  |
| `alternativeText` | textTemplate |  |  | Alternative text of the image for accessibility purposes. |
| `widthUnit` | enumeration |  | auto |  |
| `width` | integer |  | 100 |  |
| `heightUnit` | enumeration |  | auto | Auto will keep the aspect ratio of the image. |
| `height` | integer |  | 100 |  |
| `minHeightUnit` | enumeration |  | none |  |
| `minHeight` | integer | Yes | 0 |  |
| `maxHeightUnit` | enumeration |  | none |  |
| `maxHeight` | integer | Yes | 0 |  |
| `iconSize` | integer |  | 14 | The size of the icon in pixels. |
| `displayAs` | enumeration |  | fullImage |  |
| `responsive` | boolean |  | true | Image will never get larger than its original size. It can become smaller. |

