# Dev Beta Features

## Calendar Edge Day Testing

### What it does
This dev beta feature forces the calendar widgets to always display the active day circle at edge positions instead of showing today's actual date. This is useful for testing how the highlight circle looks at different positions in the calendar grid.

### How to enable
1. Open the Rocket Launcher app
2. Shake your device to reveal the settings button (or enable "Always Show Settings Button")
3. Tap the settings gear icon
4. Scroll to the "DEV BETA" section
5. Toggle ON "Calendar Edge Day Testing"
6. Widgets will automatically refresh

### What are "edge days"?
Edge days are defined as:
- **Left edge**: All Sundays in the month (leftmost column in calendar grid)
- **Right edge**: All Saturdays in the month (rightmost column in calendar grid)

When enabled, the system randomly picks one of these edge days each time the widget timeline refreshes.

### Affected widgets
- ✅ **CalendarWidget** (Medium) - Large day + calendar grid
- ✅ **DayCounterWidget** (Small) - Day number display
- ✅ **CalendarViewerWidget** (Small) - Mini calendar grid

### Technical details
- **UserDefaults key**: `CalendarEdgeDayTesting` (stored in App Group)
- **Implementation**: `overrideDay` parameter in `CalendarEntry`
- **Selection algorithm**: Random edge day picked per timeline update
- **Widget refresh**: Automatic via `WidgetCenter.shared.reloadAllTimelines()`

### Use cases
- Test highlight circle visibility at calendar edges
- Verify layout doesn't break with edge cases
- Preview how widgets look with different day positions
- Debug styling issues at month boundaries
- Test weekend/weekday styling at edges

### Notes
- When disabled, widgets show today's actual date normally
- Edge day selection changes when widgets refresh (hourly or manual)
- The same edge day is used for all calendar widgets during one timeline period
- Does not affect the actual date display in DayCounterWidget (only the large number)

### Disabling
Simply toggle OFF "Calendar Edge Day Testing" in Settings → DEV BETA, and widgets will return to showing today's actual date.

---

**Added:** October 27, 2025  
**Version:** 1.2+  
**Developer:** Raudel Alejandro
