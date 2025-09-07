# 🚀 Rocket Launcher

> A powerful iOS widget-based app launcher that brings your favorite apps right to your home screen

[![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://swift.org/)
[![Xcode](https://img.shields.io/badge/Xcode-15.0+-blue.svg)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## ✨ Features

### 🎯 Core Functionality
- **5 Customizable Widgets** - Each widget displays up to 8 app shortcuts
- **40 Total App Slots** - Organize all your favorite apps across multiple widgets
- **Instant App Launch** - One-tap launching via URL schemes with haptic feedback
- **Smart Widget Management** - Easy configuration and real-time updates

### 🎨 Customization
- **RGB Color Controls** - Fine-tune widget background colors with live preview
- **Hex Color Input** - Direct hex color entry for precise styling
- **Text Alignment** - Left, center, or right alignment options
- **Custom Fonts** - Support for system and custom font families
- **Line Spacing** - Adjust vertical spacing between app names

### ⚙️ Advanced Features
- **Shake-to-Access Settings** - Hidden settings accessible via device shake
- **Backup & Restore** - Export/import configurations in JSON format
- **Test Launch** - Verify URL schemes before adding to widgets
- **Blackout Privacy** - Automatic black overlay when app enters background
- **Rich Haptics** - Tactile feedback throughout the interface

## 📱 Screenshots

![Rocket Launcher App Preview](https://drive.google.com/uc?id=12dK6583ZFMGWuOswm4lsreXhpXHnrxXY)

*App interface showing widget configuration and launcher functionality*

## 🚀 Getting Started

### Prerequisites
- iOS 15.0 or later
- Xcode 15.0 or later
- Active Apple Developer account (for deployment)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/r0bledas/rocket-launcher-x.git
   cd rocket-launcher-x
   ```

2. **Open in Xcode**
   ```bash
   open "Rocket Launcher.xcodeproj"
   ```

3. **Configure App Group**
   - Ensure the App Group ID `group.com.Robledas.rocketlauncher.Rocket-Launcher` is properly configured
   - Update with your own App Group ID if needed

4. **Build and Run**
   - Select your target device
   - Build and run the project (⌘+R)

### Adding Widgets to Home Screen

1. Long-press on your home screen
2. Tap the "+" button in the top-left corner
3. Search for "Rocket Launcher"
4. Select the large widget size
5. Add multiple widgets as needed (up to 5 supported)

## 🛠️ Configuration

### Setting Up App Launchers

1. **Open Rocket Launcher app**
2. **Tap "Add Apps"**
3. **For each app slot:**
   - Enter a display name
   - Add the app's URL scheme (e.g., `instagram://`, `spotify://`)
   - Use "Test Launch" to verify the scheme works

### Finding URL Schemes

Common URL schemes for popular apps:
- **Instagram**: `instagram://`
- **Spotify**: `spotify://`
- **YouTube**: `youtube://`
- **Settings**: `prefs:root=`
- **Camera**: `camera://`
- **Twitter**: `twitter://`
- **TikTok**: `tiktok://`
- **WhatsApp**: `whatsapp://`

> **Tip**: Many apps publish their URL schemes in their documentation, or you can use tools like [iOS App URL Scheme Reference](https://ios.gadgethacks.com/news/always-updated-list-ios-app-url-scheme-names-paths-for-shortcuts-0184033/)

### Customizing Widget Appearance

1. **Tap "Configure Widget"**
2. **Adjust colors using:**
   - RGB sliders for intuitive color mixing
   - Direct hex input for precise colors
3. **Set text alignment and spacing**
4. **Tap "Apply to Widgets"** to save changes

## 🔧 Advanced Usage

### Shake Detection Settings
- Shake your device to reveal hidden settings
- Toggle "Always Show Settings Button" to make settings always accessible
- Automatic cooldown prevents accidental triggers

### Backup & Restore
```json
{
  "exportDate": "2025-09-06T10:00:00Z",
  "appVersion": "1.0.0",
  "launchers": [
    {
      "id": 0,
      "name": "Instagram",
      "urlScheme": "instagram://"
    }
  ]
}
```

## 📋 App Group Configuration

The app uses App Groups to share data between the main app and widgets:

```swift
let appGroupID = "group.com.Robledas.rocketlauncher.Rocket-Launcher"
```

Make sure this App Group is:
- ✅ Enabled in your Apple Developer account
- ✅ Added to both app and widget targets
- ✅ Properly configured in entitlements files

## 🏗️ Architecture

### Project Structure
```
Rocket Launcher/
├── ContentView.swift          # Main app interface
├── Rocket_LauncherApp.swift   # App entry point & URL handling
├── WidgetSetupView.swift      # Widget setup guide
└── ImmersiveHostingController.swift

Rocket Launcher Widget/
├── RocketLauncherWidget.swift      # Widget implementations
├── RocketLauncherWidgetBundle.swift # Widget bundle
├── SharedTypes.swift               # Shared data types
└── WidgetConfigurationView.swift   # Widget appearance config
```

### Data Flow
1. **User configures app** → Data saved to App Group UserDefaults
2. **Widget timeline updates** → Reads from shared UserDefaults
3. **User taps widget** → Sends URL scheme to main app
4. **Main app launches target** → Provides haptic feedback

### Key Components

#### URLHandler Class
Processes widget taps and launches target apps:
```swift
// Widget tap: rocketlauncher://launch?scheme=instagram://
// App processes and launches: instagram://
```

#### Widget System
- **5 separate widget kinds** for multiple home screen instances
- **TimelineProvider** for efficient widget updates
- **App Group integration** for data sharing

## 🎨 Customization

### Adding More Widgets
To support additional widgets beyond the current 5:

1. **Create new widget struct** in `RocketLauncherWidget.swift`
2. **Add to widget bundle** in `RocketLauncherWidgetBundle.swift`
3. **Update app logic** to handle additional widget indices
4. **Increase total app slots** (currently 40 = 5 × 8)

### Modifying Widget Layout
Widgets currently support 8 apps each in a vertical list. To modify:

1. **Update `LauncherWidgetEntryView`** for different layouts
2. **Adjust `loadAppsForWidget()`** function for new slot counts
3. **Update configuration UI** to match new structure

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Make your changes**
4. **Add tests** if applicable
5. **Commit your changes** (`git commit -m 'Add amazing feature'`)
6. **Push to branch** (`git push origin feature/amazing-feature`)
7. **Open a Pull Request**

### Development Guidelines
- Follow Swift style guidelines
- Add documentation for new features
- Test on multiple iOS versions when possible
- Ensure widget functionality works correctly

## 🐛 Troubleshooting

### Common Issues

**Widget not updating?**
- Try the "Refresh All Widgets" button in the main app
- Remove and re-add the widget to your home screen

**App not launching from widget?**
- Verify the URL scheme is correct
- Use "Test Launch" to validate the scheme
- Check that the target app is installed

**Settings not accessible?**
- Shake your device to reveal the settings button
- Or enable "Always Show Settings Button" in settings

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Apple** for WidgetKit framework
- **SwiftUI** for modern iOS UI development
- **Community** for URL scheme references and testing

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/r0bledas/rocket-launcher-x/issues)
- **Discussions**: [GitHub Discussions](https://github.com/r0bledas/rocket-launcher-x/discussions)

## 🔮 Roadmap

- [ ] **Custom widget sizes** (small, medium, large)
- [ ] **App icon fetching** for visual app representation
- [ ] **Dark/light theme** automatic switching
- [ ] **Siri Shortcuts** integration
- [ ] **Apple Watch** companion app
- [ ] **Focus Mode** integration for contextual widgets

---

<div align="center">

**⭐ Star this repo if you find it useful! ⭐**

Made with ❤️ by [Raudel Alejandro](https://github.com/r0bledas)

</div>
