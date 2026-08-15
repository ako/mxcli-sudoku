# Feedback

- **Widget ID:** `SprintrFeedbackWidget.SprintrFeedback`
- **Type:** PLUGGABLEWIDGET
- **Version:** 12.0.1

## MDL Example

```sql
PLUGGABLEWIDGET 'SprintrFeedbackWidget.SprintrFeedback' widget1
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `feedbackButtonAction` | action | Yes | FeedbackModule.ACT_Open_Feedback_Modal | The default on-click action is the 'ACT_Open_Feedback_Modal' nanoflow, which ... |
| `sprintrapp` | string | Yes | 1 | The App ID is added automatically by Studio Pro. You can find it in the Devel... |
| `showAdvancedSettings` | boolean | Yes | false | These advanced settings control html2canvas, a backup screen capture tool the... |
| `foreignObjectRendering` | boolean | Yes | false | Only enable this when you experience problems with creating screenshots.
    ... |
| `scrollableAreaSelector` | string |  | .mx-scrollcontainer-fixed > .mx-scrollcontainer-middle > .mx-scrollcontainer-wrapper | If your app doesn't use the default scrolling behavior in Studio Pro, the scr... |
| `title_label` | textTemplate |  |  |  |
| `take_screenshot_label` | textTemplate |  |  |  |
| `annotate_label` | textTemplate |  |  |  |
| `done_label` | textTemplate |  |  |  |
| `cancel_label` | textTemplate |  |  |  |
| `clear_label` | textTemplate |  |  | 
These button labels are only used by the Feedback Button, Take Screenshot an... |
| `userDefinedButtonStyle` | enumeration | Yes | side | Choose how the feedback button renders on your apps page.
If set to 'Do not r... |
| `showInDesignMode` | boolean | Yes | true | In Mendix Studio Pro you can show or hide the Feedback widget button from the... |

