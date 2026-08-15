# Video Player

- **Widget ID:** `com.mendix.widget.web.videoplayer.VideoPlayer`
- **Type:** PLUGGABLEWIDGET
- **Version:** 3.2.3

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.videoplayer.VideoPlayer' widget1
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `type` | enumeration | Yes | dynamic |  |
| `urlExpression` | expression |  |  | The web address of the video: YouTube, Vimeo, Dailymotion or MP4. |
| `posterExpression` | expression |  |  | The web address of the poster image. A poster image is a custom preview image... |
| `videoUrl` | textTemplate |  |  | The web address of the video: YouTube, Vimeo, Dailymotion or MP4. |
| `posterUrl` | textTemplate |  |  | The web address of the poster image. A poster image is a custom preview image... |
| `iframeTitle` | textTemplate |  |  | Describe the purpose of the video (e.g., 'Video tutorial on accessibility'). |
| `autoStart` | boolean | Yes | false | Automatically start playing the video when the page loads. |
| `showControls` | boolean | Yes | true | Display video controls (control bar, display icons, dock buttons). Available ... |
| `muted` | boolean | Yes | false | Start the video on mute. |
| `loop` | boolean | Yes | false | Loop the video after it finishes. Available for YouTube, Vimeo, and external ... |
| `widthUnit` | enumeration | Yes | percentage | Percentage: portion of parent size. Pixels: absolute amount of pixels. |
| `width` | integer | Yes | 100 |  |
| `heightUnit` | enumeration | Yes | aspectRatio | Aspect ratio: ratio of width to height. Percentage of parent: portion of pare... |
| `heightAspectRatio` | enumeration | Yes | sixteenByNine | 16:9 (Widescreen, HD Video), 4:3 (Classic TV, Standard monitor), 3:2 (Classic... |
| `height` | integer | Yes | 500 |  |

