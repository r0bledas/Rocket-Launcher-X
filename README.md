# 🚀 Rocket Launcher X

> A sophisticated iOS widget-based app launcher suite with Apple Watch sync, calendar widgets, flip clock, countdown timer, and sales counter

[![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://swift.org/)
[![Xcode](https://img.shields.io/badge/Xcode-15.0+-blue.svg)](https://developer.apple.com/xcode/)
[![watchOS](https://img.shields.io/badge/watchOS-Compatible-green.svg)](https://developer.apple.com/watchos/)

## ✨ Overview

**Rocket Launcher X** combines multiple productivity tools into one powerful iOS app:
- **5 App Launcher Widgets** - Quick access to 40 apps via custom URL schemes
- **3 Calendar Widgets** - Medium, small day counter, and mini calendar viewer
- **Flip Clock Widget** - Real-time animated digital clock
- **MultiTimeX Timer** - Countdown timer with Live Activity support

## 🏗️ Architecture

### Main Components

#### 1. **Main iOS App** (`Rocket Launcher/`)
- **Rocket_LauncherApp.swift** - Main app entry point with URL scheme handling
- **ContentView.swift** - Three-page tab interface:
  - Page 0: Rocket Launcher (Main app launcher interface)
  - Page 2: MultiTimeX Timer with Live Activity
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
#### 3. **Apple Watch App** (`Rocket Launcher Watch App/`)
- Web Launcher and MultiTimeX Timer

#### 4. **Shared App Group**
- Group ID: `group.rocketlauncher`
- Shared UserDefaults for widget data, customization settings, and app configurations

## 🚀 Core Features

### 1. App Launcher Widgets (5 Large Widgets)

**Quick access to up to 40 apps via custom URL schemes**

- **5 independent widgets**, each with 8 app slots
- **Custom URL schemes** for launching any app
- **Haptic feedback** on launch (heavy impact)
- **Icon support** - Fetch and display app icons from iTunes/Iconfinder
- **Deep customization:**
  - Background color (RGB/Hex)
  - Font color
  - Line spacing (-10 to 20)
  - Text alignment (left/center/right)
  - Custom fonts
  - Toggle icons on/off globally or per app
- **Test Launch** - Verify URL schemes before adding to widgets

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
- Refreshes hourly and at midnight

#### DayCounterWidget (Small)
- Large day number display
- Full date string
- Day of year counter (X/365)

#### CalendarViewerWidget (Small)
- Compact monthly calendar grid
- Current day highlighted
- Weekday headers (S M T W T F S)

### 3. FlipClockWidget (Small)
- Real-time digital clock display
- Blinking colon animation (toggles every second)
- 3D rotation effect
- Monospaced font for clean alignment
- Timeline updates every 0.5 seconds

### 4. MultiTimeX Countdown Timer

**Location:** Page 2 (swipe right from main)

- Set target time with day selector (Today/Tomorrow)
- Large countdown display with hours, minutes, seconds
- Progress bar with percentage
- **Live Activity support** for always-on display
- Completion alert when timer reaches zero
- Landscape mode support with dynamic font scaling
- Haptic feedback on start/stop
- Only allows future times (validates input)



## 📱 Screenshots

![Rocket Launcher App Preview](https://drive.google.com/uc?id=12dK6583ZFMGWuOswm4lsreXhpXHnrxXY)

*App interface showing widget configuration and launcher functionality*

## 🚀 Quick Start

1. **Build & Install** - Open `Rocket Launcher.xcodeproj` in Xcode and run
2. **Add Widgets** - Long-press home screen → "+" → Search "Rocket Launcher"
3. **Configure Apps** - Open app → "Add Apps" → Enter app names and URL schemes
4. **Customize Appearance** - Tap "Configure Widget" → Adjust colors, fonts, spacing
5. **Access Settings** - Shake device or enable "Always Show Settings Button"

## 🎨 Customization System

### Widget Configuration
Access via "Configure Widget" button in the main app

**Customizable Properties:**

1. **Background Color**
   - RGB sliders (0-255)
   - Hex color input (#RRGGBB or #RRGGBBAA)
   - Live preview
   - Transparent support (#00000000)

2. **Font Color**
   - RGB sliders
   - Hex input
   - Live preview

3. **Calendar Highlight Color**
   - RGB sliders
   - Hex input
   - Affects all calendar widgets

4. **Line Spacing**
   - Slider control (-10 to 20)
   - Default: -0.5
   - Adjusts vertical spacing between app names

5. **Text Alignment**
   - Left, Center, Right
   - Picker selection
   - Applies to all app launcher widgets

6. **Font Selection**
   - System font (default)
   - Custom font picker
   - Stored as font name string

7. **Icon Toggle**
   - Global icons enabled/disabled
   - Per-app icon visibility control
   - Fetch icons from iTunes/Iconfinder

**Storage:** All settings saved to App Group UserDefaults:
```
- WidgetBackgroundColor: String (hex)
- WidgetFontColor: String (hex)
- CalendarHighlightColor: String (hex)
- WidgetLineSpacing: Double
- WidgetTextAlignment: String
- WidgetFontName: String
- WidgetIconsEnabled: Bool
```

### App Management
Access via "Add Apps" button (WidgetLaunchersConfigView)

**Features:**
- Edit all 40 app slots across 5 widgets
- For each app:
  - Name (displayed in widget)
  - URL Scheme (e.g., `instagram://`)
  - Icon (automatically fetched)
  - Show Icon toggle (per-app visibility)
- **Test Launch** - Tap to verify URL scheme works before saving
- **Backup & Restore** - Export/import configurations in JSON format

**Data Storage:**
- Key: `AppLaunchers` in App Group UserDefaults
- Format: JSON encoded array of app launcher objects

## 🛠️ Common URL Schemes

- **Instagram**: `instagram://`
- **Spotify**: `spotify://`
- **YouTube**: `youtube://`
- **Settings**: `prefs:root=`
- **Camera**: `camera://`
- **Twitter**: `twitter://`
- **WhatsApp**: `whatsapp://`
- **Safari**: `https://`
- **Maps**: `maps://`
- **Mail**: `mailto://`
- **Phone**: `tel://`
- **Messages**: `sms://`
- **FaceTime**: `facetime://`
- **App Store**: `itms-apps://`
- **Music**: `music://`
- **Photos**: `photos-redirect://`

## 🧪 Dev Beta Features

### Calendar Edge Day Testing

This development feature forces calendar widgets to always display the highlight circle at edge positions (Sundays and Saturdays) for testing layout behavior.

**How to enable:**
1. Shake device to reveal settings (or enable "Always Show Settings Button")
2. Tap settings gear icon
3. Scroll to "DEV BETA" section
4. Toggle ON "Calendar Edge Day Testing"
5. Widgets automatically refresh

**What are "edge days"?**
- **Left edge**: All Sundays (leftmost column in calendar grid)
- **Right edge**: All Saturdays (rightmost column in calendar grid)

When enabled, the system randomly picks one edge day each time widgets refresh.

**Affected widgets:**
- ✅ CalendarWidget (Medium)
- ✅ DayCounterWidget (Small)
- ✅ CalendarViewerWidget (Small)

**Technical details:**
- UserDefaults key: `CalendarEdgeDayTesting` (stored in App Group)
- Implementation: `overrideDay` parameter in `CalendarEntry`
- Selection algorithm: Random edge day picked per timeline update
- Automatic widget refresh via `WidgetCenter.shared.reloadAllTimelines()`

**Use cases:**
- Test highlight circle visibility at calendar edges
- Verify layout doesn't break with edge cases
- Preview widgets with different day positions
- Debug styling issues at month boundaries
- Test weekend/weekday styling at edges

**To disable:** Toggle OFF in Settings → DEV BETA

---

**Dev Beta Added:** October 27, 2025  
**Version:** 1.2+

## 🐛 Troubleshooting

**Widget not updating?** 
- Try "Refresh All Widgets" button in the app
- Remove and re-add the widget
- Ensure App Group ID is configured correctly in all targets

**App not launching?** 
- Verify URL scheme with "Test Launch" button
- Ensure target app is installed on device
- Check if URL scheme is correct (some apps require specific formats)

**Can't access settings?** 
- Shake device to reveal settings button
- Enable "Always Show Settings Button" in settings

**Calendar widgets showing wrong date?**
- Check if "Calendar Edge Day Testing" is enabled in Dev Beta settings
- Widgets refresh hourly; wait for next update or use "Refresh All Widgets"

## 📝 Technical Details

### Widget Timeline Updates
- **App Launcher Widgets**: On-demand (when app data changes)
- **Calendar Widgets**: Hourly + major refresh at midnight
- **FlipClockWidget**: Every 0.5 seconds for smooth animation
- **DayCounterWidget**: Hourly

### Data Persistence
- **UserDefaults App Group**: `group.rocketlauncher`

- **JSON Export/Import**: Backup and restore all app launcher configurations

### Requirements
- **iOS**: 15.0+
- **watchOS**: 8.0+ (for Watch app)
- **Xcode**: 15.0+
- **Swift**: 5.0+

## 📝 License

MIT License - See [LICENSE](LICENSE) file for details

---

<div align="center">

Made with ❤️ by [Raudel Alejandro](https://github.com/r0bledas)

**⭐ Star this repo if you find it useful! ⭐**

</div>
