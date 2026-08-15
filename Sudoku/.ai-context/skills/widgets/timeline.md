# Timeline

- **Widget ID:** `com.mendix.widget.web.timeline.Timeline`
- **Type:** PLUGGABLEWIDGET
- **Version:** 3.2.2

## MDL Example

```sql
PLUGGABLEWIDGET 'com.mendix.widget.web.timeline.Timeline' widget1 {
  customicon {
    -- widgets for `customIcon`
  }
  customgroupheader {
    -- widgets for `customGroupHeader`
  }
  customtitle {
    -- widgets for `customTitle`
  }
  customeventdatetime {
    -- widgets for `customEventDateTime`
  }
  customdescription {
    -- widgets for `customDescription`
  }
}
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `data` | datasource | Yes |  |  |
| `title` | textTemplate |  |  |  |
| `description` | textTemplate |  |  |  |
| `timeIndication` | textTemplate |  |  |  |
| `customVisualization` | boolean | Yes | false | Enables free to model timeline. |
| `icon` | icon |  |  | If no icon is configured, a circle will be rendered. |
| `groupEvents` | boolean | Yes | true | Shows a header between grouped events based on event date. |
| `groupAttribute` | attribute |  |  | Will be used for grouping events, as a group header value. If events have no ... |
| `groupByKey` | enumeration | Yes | day | Group events based on day, month or year. |
| `groupByDayOptions` | enumeration | Yes | dayName | Format group header with current language's format |
| `groupByMonthOptions` | enumeration | Yes | month |  |
| `ungroupedEventsPosition` | enumeration | Yes | end | Position in the list of events without a date and time |
| `customIcon` | widgets |  |  | Content of the icon |
| `customGroupHeader` | widgets |  |  | Content of the group header |
| `customTitle` | widgets |  |  | Content of the title |
| `customEventDateTime` | widgets |  |  | Content of the event time |
| `customDescription` | widgets |  |  | Content of the description |
| `onClick` | action |  |  |  |

## Child Slots (curly-brace blocks)

| MDL keyword | Widget property |
|-------------|----------------|
| `customicon` | `customIcon` |
| `customgroupheader` | `customGroupHeader` |
| `customtitle` | `customTitle` |
| `customeventdatetime` | `customEventDateTime` |
| `customdescription` | `customDescription` |

