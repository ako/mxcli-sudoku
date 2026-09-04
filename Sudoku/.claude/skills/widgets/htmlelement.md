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

| Property | Type | Required | Default | Values / notes | Group | Description |
|----------|------|----------|---------|----------------|-------|-------------|
| `tagName` | enumeration | Yes | div | `div` \| `span` \| `p` \| `ul` \| `ol` \| `li` \| `a` \| `img` \| `h1` \| `h2` \| `h3` \| `h4` \| `h5` \| `h6` \| `__customTag__` | General::HTML element | Tag name |
| `tagNameCustom` | string |  | div |  | General::HTML element | Custom tag |
| `tagUseRepeat` | boolean | Yes | false |  | General::HTML element | Repeat element for each item in data source. |
| `tagContentRepeatDataSource` | datasource | Yes |  | list | General::HTML element | Data source |
| `tagContentMode` | enumeration | Yes | container | `container` \| `innerHTML` | General::HTML element | Content |
| `tagContentHTML` | textTemplate |  |  |  | General::HTML element | HTML |
| `tagContentContainer` | widgets |  |  |  | General::HTML element | Content |
| `tagContentRepeatHTML` | textTemplate |  |  |  | General::HTML element | HTML |
| `tagContentRepeatContainer` | widgets |  |  |  | General::HTML element | Content |
| `attributes` | object |  |  | list; 6 sub-properties below | General::HTML attributes | The HTML attributes that are added to the HTML element. For example: ‘title‘, ‘href‘. If ‘class’ or ‘style’ is added as attribute this is merged with the widget class/style property. For events (e.g. onClick) use the Events section. |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `attributeName` | string | Yes |  |  |  | Name |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `attributeValueType` | enumeration | Yes | expression | `expression` \| `template` |  | Value based on |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `attributeValueTemplate` | textTemplate |  |  |  |  | Value |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `attributeValueExpression` | expression |  |  |  |  | Value |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `attributeValueTemplateRepeat` | textTemplate |  |  |  |  | Value |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `attributeValueExpressionRepeat` | expression |  |  |  |  | Value |
| `events` | object |  |  | list; 5 sub-properties below | Events | Events |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `eventName` | enumeration | Yes | onClick | `onAbort` \| `onAbortCapture` \| `onAnimationEnd` \| `onAnimationEndCapture` \| `onAnimationIteration` \| `onAnimationIterationCapture` \| `onAnimationStart` \| `onAnimationStartCapture` \| `onAuxClick` \| `onAuxClickCapture` \| `onBeforeInput` \| `onBeforeInputCapture` \| `onBlur` \| `onBlurCapture` \| `onCanPlay` \| `onCanPlayCapture` \| `onCanPlayThrough` \| `onCanPlayThroughCapture` \| `onChange` \| `onChangeCapture` \| `onClick` \| `onClickCapture` \| `onCompositionEnd` \| `onCompositionEndCapture` \| `onCompositionStart` \| `onCompositionStartCapture` \| `onCompositionUpdate` \| `onCompositionUpdateCapture` \| `onContextMenu` \| `onContextMenuCapture` \| `onCopy` \| `onCopyCapture` \| `onCut` \| `onCutCapture` \| `onDoubleClick` \| `onDoubleClickCapture` \| `onDrag` \| `onDragCapture` \| `onDragEnd` \| `onDragEndCapture` \| `onDragEnter` \| `onDragEnterCapture` \| `onDragExit` \| `onDragExitCapture` \| `onDragLeave` \| `onDragLeaveCapture` \| `onDragOver` \| `onDragOverCapture` \| `onDragStart` \| `onDragStartCapture` \| `onDrop` \| `onDropCapture` \| `onDurationChange` \| `onDurationChangeCapture` \| `onEmptied` \| `onEmptiedCapture` \| `onEncrypted` \| `onEncryptedCapture` \| `onEnded` \| `onEndedCapture` \| `onError` \| `onErrorCapture` \| `onFocus` \| `onFocusCapture` \| `onGotPointerCapture` \| `onGotPointerCaptureCapture` \| `onInput` \| `onInputCapture` \| `onInvalid` \| `onInvalidCapture` \| `onKeyDown` \| `onKeyDownCapture` \| `onKeyPress` \| `onKeyPressCapture` \| `onKeyUp` \| `onKeyUpCapture` \| `onLeave` \| `onLoad` \| `onLoadCapture` \| `onLoadedData` \| `onLoadedDataCapture` \| `onLoadedMetadata` \| `onLoadedMetadataCapture` \| `onLoadStart` \| `onLoadStartCapture` \| `onLostPointerCapture` \| `onLostPointerCaptureCapture` \| `onMouseDown` \| `onMouseDownCapture` \| `onMouseEnter` \| `onMouseLeave` \| `onMouseMove` \| `onMouseMoveCapture` \| `onMouseOut` \| `onMouseOutCapture` \| `onMouseOver` \| `onMouseOverCapture` \| `onMouseUp` \| `onMouseUpCapture` \| `onPaste` \| `onPasteCapture` \| `onPause` \| `onPauseCapture` \| `onPlay` \| `onPlayCapture` \| `onPlaying` \| `onPlayingCapture` \| `onPointerCancel` \| `onPointerCancelCapture` \| `onPointerDown` \| `onPointerDownCapture` \| `onPointerEnter` \| `onPointerEnterCapture` \| `onPointerLeave` \| `onPointerLeaveCapture` \| `onPointerMove` \| `onPointerMoveCapture` \| `onPointerOut` \| `onPointerOutCapture` \| `onPointerOver` \| `onPointerOverCapture` \| `onPointerUp` \| `onPointerUpCapture` \| `onProgress` \| `onProgressCapture` \| `onRateChange` \| `onRateChangeCapture` \| `onReset` \| `onResetCapture` \| `onScroll` \| `onScrollCapture` \| `onSeeked` \| `onSeekedCapture` \| `onSeeking` \| `onSeekingCapture` \| `onSelect` \| `onSelectCapture` \| `onStalled` \| `onStalledCapture` \| `onSubmit` \| `onSubmitCapture` \| `onSuspend` \| `onSuspendCapture` \| `onTimeUpdate` \| `onTimeUpdateCapture` \| `onTouchCancel` \| `onTouchCancelCapture` \| `onTouchEnd` \| `onTouchEndCapture` \| `onTouchMove` \| `onTouchMoveCapture` \| `onTouchStart` \| `onTouchStartCapture` \| `onTransitionEnd` \| `onTransitionEndCapture` \| `onVolumeChange` \| `onVolumeChangeCapture` \| `onWaiting` \| `onWaitingCapture` \| `onWheel` \| `onWheelCapture` |  | Name |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `eventAction` | action |  |  |  |  | Action |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `eventActionRepeat` | action |  |  |  |  | Action |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `eventStopPropagation` | boolean | Yes | true |  |  | Stop propagation |
| &nbsp;&nbsp;&nbsp;&nbsp;↳ `eventPreventDefault` | boolean | Yes | true |  |  | Prevent default |
| `sanitizationConfigFull` | string |  |  |  | Advanced::HTML Sanitization | Configuration for HTML sanitization in JSON format. Leave blank for default. |

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

---

Regenerated by `mxcli widget docs` and by `refresh catalog`. For the same data live from the `.mpk` — including anything added by a widget upgrade since this file was written — run `mxcli widget describe htmlelement -p <app.mpr>`.
