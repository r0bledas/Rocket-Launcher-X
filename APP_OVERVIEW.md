# Rocket Launcher X - Complete App Overview

## 📱 App Summary
**Rocket Launcher X** is a sophisticated iOS app that provides **widget-based app launchers** with deep customization options. The app combines multiple features including app launching widgets, calendar widgets, a flip clock, a countdown timer (MultiTimeX), and a sales counter with Apple Watch sync.

---

## 🏗️ Architecture

### Main Components

#### 1. **Main iOS App** (`Rocket Launcher/`)
- **Rocket_LauncherApp.swift** - Main app entry point with URL scheme handling
- **ContentView.swift** - Three-page tab interface:
  - Page 0: Sales Counter
  - Page 1: Rocket Launcher (Main)
  - Page 2: MultiTimeX Timer
- **AppLauncherStore** - Manages 40 app launcher slots (5 widgets × 8 apps each)
- **ShakeDetector** - CoreMotion-based shake detection for hidden settings

#### 2. **Widget Extension** (`Rocket Launcher Widget/`)
- **RocketLauncherWidgetBundle.swift** - Bundles all widgets:
  - 5 Large App Launcher Widgets (RocketLauncherWidget 1-5)
  - CalendarWidget (Medium)
  - DayCounterWidget (Small)
  - CalendarViewerWidget (Small)
  - FlipClockWidget (Small)
  - MultiTimeXLiveActivity (Live Activity)

#### 3. **Apple Watch App** (`Rocket Launcher Watch App/`)
- Sales counter with WatchConnectivity sync
- Real-time bidirectional sync with iOS app

---

## 🚀 Core Features

### 1. App Launcher Widgets (5 Widgets)
**Purpose:** Quick access to up to 40 apps via custom URL schemes

**Key Features:**
- **5 independent widgets**, each with 8 app slots
- **Custom URL schemes** for launching any app
- **Haptic feedback** on launch (heavy impact)
- **Icon support** - Fetch and display app icons
- **Deep customization:**
  - Background color (RGB/Hex)
  - Font color
  - Line spacing
  - Text alignment (left/center/right)
  - Custom fonts
  - Toggle icons on/off per app
- **Widget data storage:** App Group UserDefaults
  - Group ID: `group.com.Robledas.rocketlauncher.Rocket-Launcher`
  - Key: `AppLaunchers` (JSON encoded array)

**URL Scheme Format:**
```
rocketlauncher://launch?scheme=<app-url-scheme>
```

**Widget Structure:**
- Widget #1: Apps 0-7
- Widget #2: Apps 8-15
- Widget #3: Apps 16-23
- Widget #4: Apps 24-31
- Widget #5: Apps 32-39

### 2. Calendar Widgets (3 Variants)

#### CalendarWidget (Medium)
- Left side: Large day number, full date, day of year (X/365)
- Right side: Mini calendar grid with current day highlighted
- Customizable highlight color
- Weekend days automatically dimmed

#### DayCounterWidget (Small)
- Large day number display
- Full date string
- Day of year counter

#### CalendarViewerWidget (Small)
- Compact monthly calendar grid
- Current day highlighted
- Weekday headers (S M T W T F S)

**Timeline Updates:**
- Refreshes every hour
- Major refresh at midnight
- Uses CalendarProvider with shared color settings

### 3. FlipClockWidget (Small)
- Real-time digital clock display
- Blinking colon animation (toggles every second)
- 3D rotation effect
- Monospaced font
- Timeline updates every 0.5 seconds

### 4. MultiTimeX Timer
**Location:** Page 2 (swipe right from main)

**Features:**
- Set target time with day selector (Today/Tomorrow)
- Large countdown display
- Progress bar with percentage
- Live Activity support for always-on display
- Completion alert when timer reaches zero
- Landscape mode support with dynamic font scaling
- Haptic feedback on start/stop

**Timer States:**
- Setup view: DatePicker + Day selector
- Running view: Large time display + Stop button
- Validation: Only allows future times

### 5. Sales Counter
**Location:** Page 0 (swipe left from main)

**Features:**
- Track sales of multiple items (default: KitKat, Oreo)
- Increment/decrement counts
- Calculate total revenue and profit
- Reset all counts
- **Apple Watch sync** via WatchConnectivity
- Persistent storage in UserDefaults
- Real-time bidirectional updates

**Data Structure:**
```swift
struct SalesItem {
    let id: String
    var name: String
    var unitPrice: Double
    var unitCost: Double
    var count: Int
}
```

---

## 🎨 Customization System

### Widget Configuration View
Access via "Configure Widget" button

**Customizable Properties:**
1. **Background Color**
   - RGB sliders (0-255)
   - Hex color input
   - Live preview
   - Clear/transparent support (#00000000)

2. **Font Color**
   - RGB sliders
   - Hex input
   - Live preview

3. **Calendar Highlight Color**
   - RGB sliders
   - Hex input
   - Affects calendar widgets only

4. **Line Spacing**
   - Slider control (-10 to 20)
   - Default: -0.5

5. **Text Alignment**
   - Left, Center, Right
   - Picker selection

6. **Font Selection**
   - System font (default)
   - Custom font picker
   - Stored as font name string

7. **Icon Toggle**
   - Global icons enabled/disabled
   - Per-app icon visibility control

**Storage Keys (UserDefaults in App Group):**
```
- WidgetBackgroundColor: String (hex)
- WidgetFontColor: String (hex)
- CalendarHighlightColor: String (hex)
- WidgetLineSpacing: Double
- WidgetTextAlignment: String
- WidgetFontName: String
- WidgetIconsEnabled: Bool
```

### App Management (WidgetLaunchersConfigView)
Access via "Add Apps" button

**Features:**
- Edit 40 app slots across 5 widgets
- For each app:
  - Name (displayed in widget)
  - URL Scheme
  - Icon (fetch from iTunes/Iconfinder)
  - Show Icon toggle
- **Test Launch** - Verify URL scheme before saving
- **Backup/Restore** - Export/import configuration as JSON
- **Visual grouping** - 8 apps per widget section
- **Refresh widgets** after changes

---

## 🔧 Technical Details

### Data Persistence
- **App Group:** `group.com.Robledas.rocketlauncher.Rocket-Launcher`
- **Widget Refresh:** `WidgetCenter.shared.reloadAllTimelines()`
- **Icon Storage:** App Group container `/icons` directory
- **Sales Data:** UserDefaults with key `SalesState_v1`
- **Watch Sync:** WCSession message passing

### URL Handling
**Custom URL Scheme:** `rocketlauncher://`

**Supported Patterns:**
- `rocketlauncher://launch?scheme=<url-scheme>`
- Legacy: `rocketlauncher://launch?app=<url-scheme>`

**Launch Flow:**
1. Widget tap → Opens app with URL
2. App's `onOpenURL` handler catches it
3. URLHandler parses query parameters
4. Plays heavy haptic feedback
5. Opens target app via `UIApplication.shared.open()`
6. Shows alert if launch fails

### Haptic Feedback
- **Light impact:** Settings, navigation buttons
- **Medium impact:** Button presses
- **Heavy impact:** App launches, timer actions
- **Error notification:** Invalid timer selection

### Settings Access
**Two modes:**
1. **Shake to reveal** - Device shake detection via CoreMotion
   - Cooldown: 2.5 seconds
   - Auto-hide after 5 seconds
2. **Always show** - Toggle in settings

**Settings Options:**
- Always show settings button
- Export/import configuration
- About/version info

### Black Screen Effect
- Shows black overlay when app enters background
- Hides with 0.5s delay when app becomes active
- Creates seamless transition from widgets
- Works best with iOS "Reduce Motion" enabled

### Live Activities (MultiTimeX)
- Displays countdown on Lock Screen/Dynamic Island
- Updates in real-time
- Shows progress bar and percentage
- Automatically ends when timer completes

---

## 📦 Dependencies & Requirements

**iOS Version:** 15.0+
**Xcode:** 15.0+
**Swift:** 5.0+

**Frameworks Used:**
- SwiftUI
- WidgetKit
- UIKit
- CoreMotion (shake detection)
- WatchConnectivity (Watch sync)
- ActivityKit (Live Activities)
- Network (connectivity checks)
- AudioToolbox (haptics)

**Capabilities Required:**
- App Groups
- Background Modes (optional for Live Activities)
- URL Schemes (LSApplicationQueriesSchemes)

---

## 🗂️ File Structure

```
Rocket Launcher/
├── Rocket_LauncherApp.swift         # App entry, URL handling
├── ContentView.swift                # Main 3-page interface
├── WidgetSetupView.swift            # Setup guide sheet
├── WidgetConfigurationView.swift   # (Not shown, but referenced)
├── SalesCounterView.swift           # Sales tracking UI
├── SalesManager.swift               # Sales data management
└── ImmersiveHostingController.swift # (Additional views)

Rocket Launcher Widget/
├── RocketLauncherWidgetBundle.swift # Widget bundle definition
├── RocketLauncherWidget.swift       # All widget implementations
├── WidgetConfigurationView.swift    # Widget config UI
└── SharedTypes.swift                # Shared data structures

Rocket Launcher Watch App/
├── Rocket_Launcher_WatchApp.swift   # Watch app entry
├── ContentView.swift                # Watch main view
├── SalesCounterView.swift           # Watch sales UI
└── SalesManager.swift               # Watch data sync
```

---

## 🎯 User Flows

### Adding Apps to Widgets
1. Open app → "Add Apps"
2. Scroll to desired slot (1-40)
3. Enter app name and URL scheme
4. Optional: Fetch icon
5. Optional: Test launch
6. Save → Refresh widgets

### Customizing Widget Appearance
1. Open app → "Configure Widget"
2. Adjust colors via RGB sliders or hex input
3. Preview changes in real-time
4. Set line spacing and alignment
5. "Apply to Widgets" → Refreshes all

### Using MultiTimeX Timer
1. Swipe right to MultiTimeX page
2. Select day (Today/Tomorrow)
3. Pick target time on wheel
4. "Start Timer" (validates future time)
5. View countdown with progress bar
6. Optional: Check Live Activity on lock screen
7. Stop manually or wait for completion alert

### Sales Counting
1. Swipe left to Sales Counter
2. Tap + or - to adjust counts
3. View totals: units, revenue, profit
4. Reset all counts when needed
5. Changes sync to Apple Watch automatically

---

## 🔑 Key Design Patterns

### State Management
- `@StateObject` for managers (AppLauncherStore, SalesManager)
- `@Published` properties for reactive updates
- `@AppStorage` for persistent settings

### Data Sharing
- **App Group UserDefaults** for widget data
- **WatchConnectivity** for Watch sync
- **NotificationCenter** for cross-component updates

### Widget Timeline
- `TimelineProvider` protocol implementation
- `.atEnd` policy for manual refresh control
- Scheduled updates for time-based widgets

### Haptic Feedback
- Centralized `HapticsHelper` class
- Context-appropriate impact levels
- Consistent UX across app and widgets

---

## 🐛 Known Issues & Considerations

1. **URL Schemes:** Target apps must be installed and their URL schemes listed in Info.plist's `LSApplicationQueriesSchemes`
2. **Widget Refresh:** May require manual refresh via "Refresh All Widgets" button
3. **Black Screen Effect:** Works best with iOS "Reduce Motion" enabled
4. **Watch Sync:** Requires Watch app to be installed and paired
5. **Icon Fetching:** Depends on external APIs (iTunes, Iconfinder)

---

## 🎨 Color Handling

**Supported Formats:**
- 3-digit hex: `#RGB` (12-bit)
- 6-digit hex: `#RRGGBB` (24-bit)
- 8-digit hex: `#AARRGGBB` (32-bit with alpha)
- RGB values: 0-255 per channel
- Special: "clear" or `#00000000` for transparency

**Conversion:**
- Custom `Color(hex:)` extension
- Scanner-based hex parsing
- sRGB color space

---

## 📱 Widget Specifications

### Large Widgets (App Launchers)
- **Size:** systemLarge
- **Capacity:** 8 apps per widget
- **Layout:** Vertical stack with optional icons
- **Interaction:** Deep links to rocketlauncher:// scheme

### Medium Widgets (Calendar)
- **Size:** systemMedium
- **Layout:** Horizontal split (date + calendar grid)
- **Update Frequency:** Hourly + midnight refresh

### Small Widgets (Day Counter, Calendar Viewer, Flip Clock)
- **Size:** systemSmall
- **Update Frequency:** 
  - Day Counter: Hourly + midnight
  - Calendar Viewer: Hourly + midnight
  - Flip Clock: Every 0.5 seconds

---

## 🚀 Future Enhancement Ideas

Based on the code structure, potential additions could include:
- More widget sizes (systemMedium for app launchers)
- Widget configuration per widget (instead of global)
- Icon cache management
- More predefined color themes
- Export/import per widget
- Statistics tracking for most-launched apps
- Integration with Shortcuts app
- Siri support for launching apps
- Widget grouping/categories

---

## 📝 Version Information

**Current Version:** 1.2
**Bundle Version:** 1
**Bundle ID:** (Check project settings)
**App Group ID:** `group.com.Robledas.rocketlauncher.Rocket-Launcher`

---

## 👨‍💻 Developer Notes

**Creator:** Raudel Alejandro (Ra-Rauw)
**Created:** July 19, 2025
**Platform:** iOS 15.0+, watchOS (companion)

**Code Style:**
- SwiftUI declarative UI
- MARK comments for organization
- Computed properties for derived state
- Private helper functions
- Extension-based organization

**Testing Tips:**
- Use "Test Launch" before adding URL schemes
- Enable "Reduce Motion" for best widget experience
- Check console for URL handling logs (🚀, ✅, ❌ emojis)
- Use "Refresh All Widgets" after configuration changes

---

This app is a comprehensive widget-based launcher system with advanced customization, multiple utility widgets, and cross-device sync capabilities!
