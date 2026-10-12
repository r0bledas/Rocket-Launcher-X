//
//  RocketLauncherWidget.swift
//  Rocket Launcher Widget
//
//  Created by Raudel Alejandro on 19-07-2025.
//hello :)))

import WidgetKit
import SwiftUI
import UIKit // Add UIKit for haptic feedback

// Move AppLauncher to global scope
struct AppLauncher: Codable {
    let id: Int
    let name: String
    let urlScheme: String
    let iconFileName: String?
    let showIcon: Bool?
}

struct LauncherEntry: TimelineEntry {
    let date: Date
    let apps: [App]
    let backgroundColor: String
    let fontColor: String
    let lineSpacing: Double
    let textAlignment: TextAlignment
    let fontName: String
    let iconsEnabled: Bool
    let isLocked: Bool
    let widgetNumber: Int
    struct App: Hashable {
        let name: String
        let urlScheme: String
        let iconFileName: String?
        let showIcon: Bool?
    }
}

struct LauncherProvider: TimelineProvider {
    func placeholder(in context: Context) -> LauncherEntry {
        LauncherEntry(date: Date(), apps: [], backgroundColor: getBackgroundColor(), fontColor: getFontColor(), lineSpacing: 0, textAlignment: .leading, fontName: getSelectedFont(), iconsEnabled: getIconsEnabled(), isLocked: false, widgetNumber: 1)
    }
    func getSnapshot(in context: Context, completion: @escaping (LauncherEntry) -> ()) {
        let entry = loadEntry()
        completion(entry)
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<LauncherEntry>) -> ()) {
        let entry = loadEntry()
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    private func loadEntry() -> LauncherEntry {
        let userDefaults = UserDefaults(suiteName: "group.rocketlauncher")
        var apps: [LauncherEntry.App] = []
        if let data = userDefaults?.data(forKey: "AppLaunchers"),
           let launchers = try? JSONDecoder().decode([AppLauncher].self, from: data) {
            apps = launchers.prefix(8).map { LauncherEntry.App(name: $0.name, urlScheme: $0.urlScheme, iconFileName: $0.iconFileName, showIcon: $0.showIcon) }
        }
        let color = userDefaults?.string(forKey: "WidgetBackgroundColor") ?? "#242424"
        let fontColor = userDefaults?.string(forKey: "WidgetFontColor") ?? "#FFFFFF"
        let lineSpacing = userDefaults?.object(forKey: "WidgetLineSpacing") as? Double ?? -0.5
        let alignmentRaw = userDefaults?.string(forKey: "WidgetTextAlignment") ?? "leading"
        let hasPurchased = userDefaults?.bool(forKey: "HasPurchasedTextAlignment") ?? false
        let textAlignment: TextAlignment = {
            if !hasPurchased {
                return .center // Default to center when not purchased
            }
            switch alignmentRaw {
            case "center": return .center
            case "trailing": return .trailing
            default: return .leading
            }
        }()
        return LauncherEntry(date: Date(), apps: apps, backgroundColor: color, fontColor: fontColor, lineSpacing: lineSpacing, textAlignment: textAlignment, fontName: getSelectedFont(), iconsEnabled: getIconsEnabled(), isLocked: false, widgetNumber: 1)
    }
    private func getBackgroundColor() -> String {
        let userDefaults = UserDefaults(suiteName: "group.rocketlauncher")
        return userDefaults?.string(forKey: "WidgetBackgroundColor") ?? "#242424"
    }
    private func getSelectedFont() -> String {
        let userDefaults = UserDefaults(suiteName: "group.rocketlauncher")
        return userDefaults?.string(forKey: "WidgetFontName") ?? "System"
    }
    
    private func getFontColor() -> String {
        let userDefaults = UserDefaults(suiteName: "group.rocketlauncher")
        return userDefaults?.string(forKey: "WidgetFontColor") ?? "#FFFFFF"
    }

    private func getIconsEnabled() -> Bool {
        let userDefaults = UserDefaults(suiteName: "group.rocketlauncher")
        let hasPurchased = userDefaults?.bool(forKey: "HasPurchasedIconFeature") ?? false
        let iconsEnabled = userDefaults?.bool(forKey: "WidgetIconsEnabled") ?? true
        return hasPurchased && iconsEnabled
    }
}

struct LauncherWidgetEntryView: View {
    let entry: LauncherEntry
    
    // Detect if iOS Display Zoom is enabled
    private var isDisplayZoomed: Bool {
        let screen = UIScreen.main
        return screen.scale != screen.nativeScale || screen.bounds.width <= 375
    }
    
    // Calculate responsive scale factor from actual widget container geometry
    private func layoutScale(for size: CGSize) -> CGFloat {
        let extraSpacing = max(0, CGFloat(entry.lineSpacing) * 7.0)
        let referenceWidth: CGFloat = 355.0
        let referenceHeight: CGFloat = 390.0 + extraSpacing
        let widthScale = size.width > 0 ? (size.width / referenceWidth) : (isDisplayZoomed ? 0.82 : 1.0)
        let heightScale = size.height > 0 ? (size.height / referenceHeight) : (isDisplayZoomed ? 0.82 : 1.0)
        return min(1.0, min(widthScale, heightScale))
    }
    
    private var emptyStateView: some View {
        Text("👻")
            .font(.system(size: 60))
            .foregroundColor(.white.opacity(0.5))
    }
    
    @ViewBuilder
    private func appButtonView(scale: CGFloat) -> some View {
        let appFontSize: CGFloat = 36.0 * scale
        let iconSize: CGFloat = 30.0 * scale
        let iconCornerRadius: CGFloat = 6.5 * scale
        let horizontalPadding: CGFloat = 24.0 * scale
        let iconSpacing: CGFloat = 8.0 * scale
        let verticalPadding: CGFloat = 1.5 * scale
        let leadingAdjustment: CGFloat = -15.0 * scale
        let systemContentMargin: CGFloat = 16.0 * scale
        let scaledLineSpacing: CGFloat = CGFloat(entry.lineSpacing) * scale
        
        VStack(alignment: horizontalAlignmentFor(entry.textAlignment), spacing: scaledLineSpacing) {
            ForEach(Array(entry.apps.prefix(8).enumerated()), id: \.offset) { _, app in
                if !app.name.isEmpty && !app.urlScheme.isEmpty {
                    Link(destination: URL(string: "rocketlauncher://launch?scheme=\(app.urlScheme.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!) {
                        HStack(spacing: iconSpacing) {
                            if entry.iconsEnabled, (app.showIcon ?? false), let image = loadIconImage(fileName: app.iconFileName) {
                                if #available(iOS 18.0, *) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .interpolation(.high)
                                        .widgetAccentedRenderingMode(.fullColor)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: iconSize, height: iconSize)
                                        .clipShape(RoundedRectangle(cornerRadius: iconCornerRadius))
                                } else {
                                    Image(uiImage: image)
                                        .resizable()
                                        .interpolation(.high)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: iconSize, height: iconSize)
                                        .clipShape(RoundedRectangle(cornerRadius: iconCornerRadius))
                                }
                            }
                            Text(app.name)
                                .font(getCustomFont(name: entry.fontName, size: appFontSize, weight: .bold))
                                .foregroundColor(Color(hex: entry.fontColor))
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: frameAlignmentFor(entry.textAlignment))
                                .multilineTextAlignment(entry.textAlignment)
                                .padding(.vertical, verticalPadding)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.leading, (entry.textAlignment == .leading && entry.iconsEnabled && entry.apps.contains { $0.showIcon ?? false }) ? leadingAdjustment : 0)
        .padding(.horizontal, systemContentMargin)
    }
    
    var body: some View {
        ZStack {
            
            GeometryReader { geo in
                let scale = layoutScale(for: geo.size)
                let appFontSize: CGFloat = 36.0 * scale
                let horizontalPadding: CGFloat = 24.0 * scale
                let verticalPadding: CGFloat = 1.5 * scale
                let systemContentMargin: CGFloat = 16.0 * scale
                let scaledLineSpacing: CGFloat = CGFloat(entry.lineSpacing) * scale
                
                Group {
                    if entry.isLocked {
                        // Locked widget view
                        ZStack {
                            // Blurred placeholder content
                            VStack(alignment: .leading, spacing: scaledLineSpacing) {
                                ForEach(0..<8) { _ in
                                    Text("App Name")
                                        .font(getCustomFont(name: entry.fontName, size: appFontSize, weight: .bold))
                                        .foregroundColor(Color(hex: entry.fontColor))
                                        .opacity(0.3)
                                        .padding(.vertical, verticalPadding)
                                }
                            }
                            .padding(.horizontal, horizontalPadding)
                            .padding(.horizontal, systemContentMargin)
                            .blur(radius: 8)
                            
                            // Lock overlay
                            VStack(spacing: 12 * scale) {
                                Text("🔒")
                                    .font(.system(size: 80 * scale))
                                
                                Text("Widget #\(entry.widgetNumber) Locked")
                                    .font(.system(size: 18 * scale, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Tap to Unlock")
                                    .font(.system(size: 14 * scale))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding()
                        }
                    } else if entry.apps.isEmpty || entry.apps.allSatisfy({ $0.name.isEmpty }) {
                        emptyStateView
                    } else {
                        appButtonView(scale: scale)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            }
        }
    }
    
    private func getCustomFont(name: String, size: CGFloat, weight: Font.Weight) -> Font {
        if name == "System" {
            return .system(size: size, weight: weight)
        } else {
            // Try to load custom font, fallback to system if not available
            if let customFont = UIFont(name: name, size: size) {
                return Font(customFont as CTFont)
            } else {
                return .system(size: size, weight: weight)
            }
        }
    }
}

private func horizontalAlignmentFor(_ alignment: TextAlignment) -> HorizontalAlignment {
    switch alignment {
    case .leading: return .leading
    case .center: return .center
    case .trailing: return .trailing
    @unknown default: return .leading
    }
}
private func frameAlignmentFor(_ alignment: TextAlignment) -> Alignment {
    switch alignment {
    case .leading: return .leading
    case .center: return .center
    case .trailing: return .trailing
    @unknown default: return .leading
    }
}

// Helper to load apps for a specific widget index
func loadAppsForWidget(widgetIndex: Int) -> [LauncherEntry.App] {
    let userDefaults = UserDefaults(suiteName: "group.rocketlauncher")
    var apps: [LauncherEntry.App] = []
    if let data = userDefaults?.data(forKey: "AppLaunchers"),
       let launchers = try? JSONDecoder().decode([AppLauncher].self, from: data) {
        let start = widgetIndex * 8
        let end = min(start + 8, launchers.count)
        if start < end {
            apps = launchers[start..<end].map { LauncherEntry.App(name: $0.name, urlScheme: $0.urlScheme, iconFileName: $0.iconFileName, showIcon: $0.showIcon) }
        }
    }
    return apps
}

// MARK: - Icon loading helpers
private func iconsDirectoryURL() -> URL? {
    guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.rocketlauncher") else { return nil }
    let dir = container.appendingPathComponent("icons", isDirectory: true)
    return dir
}

private func loadIconImage(fileName: String?) -> UIImage? {
    guard let fileName = fileName, let dir = iconsDirectoryURL() else { return nil }
    let url = dir.appendingPathComponent(fileName)
    return UIImage(contentsOfFile: url.path)
}

// MARK: - Static Color Background & Container Helpers

/// Background for the widget's container.
///
/// In the default (light) and dark Home Screen appearances, WidgetKit renders
/// widgets in full color, so the user's static color is honored. On a tinted or
/// clear Home Screen the system uses the `accented` rendering mode and replaces
/// the background with its own Liquid Glass material — an opaque color drawn
/// there gets tinted solid white, so we stay clear and let the system's glass
/// show through.
struct StaticWidgetBackground: View {
    let hexColor: String
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        let hex = hexColor.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let resolvedColor = (hex == "00000000" || hex.lowercased() == "clear") ? Color.black.opacity(0.95) : Color(hex: hexColor)

        Group {
            if renderingMode == .accented {
                Color.clear
            } else {
                resolvedColor
            }
        }
        .ignoresSafeArea()
    }
}

extension View {
    @ViewBuilder
    func widgetContainerBackgroundModifier(hexColor: String) -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) {
                StaticWidgetBackground(hexColor: hexColor)
            }
        } else {
            self
        }
    }
}

extension WidgetConfiguration {
    func disableContentMarginsIfNeeded() -> some WidgetConfiguration {
        if #available(iOS 17.0, *) {
            return self.contentMarginsDisabled()
        } else {
            return self
        }
    }
}

struct RocketLauncherWidget: Widget {
    let kind: String = "RocketLauncherWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LauncherProvider()) { entry in
            LauncherWidgetEntryView(entry: entry)
                .widgetContainerBackgroundModifier(hexColor: entry.backgroundColor)
        }
        .disableContentMarginsIfNeeded()
        .configurationDisplayName("Widget #1")
        .description("Display and launch your favorite apps (Widget #1).")
        .supportedFamilies([.systemLarge])
    }
}

struct RocketLauncherWidget2: Widget {
    let kind: String = "RocketLauncherWidget2"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CustomLauncherProvider(widgetIndex: 1)) { entry in
            LauncherWidgetEntryView(entry: entry)
                .widgetContainerBackgroundModifier(hexColor: entry.backgroundColor)
                .widgetURL(entry.isLocked ? URL(string: "rocketlauncher://purchase?widget=2") : nil)
        }
        .disableContentMarginsIfNeeded()
        .configurationDisplayName("Widget #2")
        .description("Display and launch your favorite apps (Widget #2).")
        .supportedFamilies([.systemLarge])
    }
}

struct RocketLauncherWidget3: Widget {
    let kind: String = "RocketLauncherWidget3"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CustomLauncherProvider(widgetIndex: 2)) { entry in
            LauncherWidgetEntryView(entry: entry)
                .widgetContainerBackgroundModifier(hexColor: entry.backgroundColor)
                .widgetURL(entry.isLocked ? URL(string: "rocketlauncher://purchase?widget=3") : nil)
        }
        .disableContentMarginsIfNeeded()
        .configurationDisplayName("Widget #3")
        .description("Display and launch your favorite apps (Widget #3).")
        .supportedFamilies([.systemLarge])
    }
}

struct RocketLauncherWidget4: Widget {
    let kind: String = "RocketLauncherWidget4"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CustomLauncherProvider(widgetIndex: 3)) { entry in
            LauncherWidgetEntryView(entry: entry)
                .widgetContainerBackgroundModifier(hexColor: entry.backgroundColor)
                .widgetURL(entry.isLocked ? URL(string: "rocketlauncher://purchase?widget=4") : nil)
        }
        .disableContentMarginsIfNeeded()
        .configurationDisplayName("Widget #4")
        .description("Display and launch your favorite apps (Widget #4).")
        .supportedFamilies([.systemLarge])
    }
}

struct RocketLauncherWidget5: Widget {
    let kind: String = "RocketLauncherWidget5"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CustomLauncherProvider(widgetIndex: 4)) { entry in
            LauncherWidgetEntryView(entry: entry)
                .widgetContainerBackgroundModifier(hexColor: entry.backgroundColor)
                .widgetURL(entry.isLocked ? URL(string: "rocketlauncher://purchase?widget=5") : nil)
        }
        .disableContentMarginsIfNeeded()
        .configurationDisplayName("Widget #5")
        .description("Display and launch your favorite apps (Widget #5).")
        .supportedFamilies([.systemLarge])
    }
}

// Custom provider for each widget
struct CustomLauncherProvider: TimelineProvider {
    let widgetIndex: Int
    func placeholder(in context: Context) -> LauncherEntry {
        let (lineSpacing, textAlignment) = getSpacingAndAlignment()
        let hasPurchased = hasPurchasedExtraWidgets()
        let isLocked = widgetIndex >= 1 && !hasPurchased
        let apps = isLocked ? [] : loadAppsForWidget(widgetIndex: widgetIndex)
        return LauncherEntry(date: Date(), apps: apps, backgroundColor: getBackgroundColor(), fontColor: getFontColor(), lineSpacing: lineSpacing, textAlignment: textAlignment, fontName: getSelectedFont(), iconsEnabled: getIconsEnabled(), isLocked: isLocked, widgetNumber: widgetIndex + 1)
    }
    func getSnapshot(in context: Context, completion: @escaping (LauncherEntry) -> ()) {
        let (lineSpacing, textAlignment) = getSpacingAndAlignment()
        let hasPurchased = hasPurchasedExtraWidgets()
        let isLocked = widgetIndex >= 1 && !hasPurchased
        let apps = isLocked ? [] : loadAppsForWidget(widgetIndex: widgetIndex)
        let entry = LauncherEntry(date: Date(), apps: apps, backgroundColor: getBackgroundColor(), fontColor: getFontColor(), lineSpacing: lineSpacing, textAlignment: textAlignment, fontName: getSelectedFont(), iconsEnabled: getIconsEnabled(), isLocked: isLocked, widgetNumber: widgetIndex + 1)
        completion(entry)
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<LauncherEntry>) -> ()) {
        let (lineSpacing, textAlignment) = getSpacingAndAlignment()
        let hasPurchased = hasPurchasedExtraWidgets()
        let isLocked = widgetIndex >= 1 && !hasPurchased
        let apps = isLocked ? [] : loadAppsForWidget(widgetIndex: widgetIndex)
        let entry = LauncherEntry(date: Date(), apps: apps, backgroundColor: getBackgroundColor(), fontColor: getFontColor(), lineSpacing: lineSpacing, textAlignment: textAlignment, fontName: getSelectedFont(), iconsEnabled: getIconsEnabled(), isLocked: isLocked, widgetNumber: widgetIndex + 1)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    private func hasPurchasedExtraWidgets() -> Bool {
        let userDefaults = UserDefaults(suiteName: "group.rocketlauncher")
        if userDefaults?.bool(forKey: "HasPurchasedExtraWidgets") ?? false { return true }
        // Temporary unlock granted via a rewarded ad.
        if let ts = userDefaults?.object(forKey: "ExtraWidgetsUnlockUntil") as? Double,
           ts > Date().timeIntervalSince1970 {
            return true
        }
        return false
    }
    private func getBackgroundColor() -> String {
        let userDefaults = UserDefaults(suiteName: "group.rocketlauncher")
        return userDefaults?.string(forKey: "WidgetBackgroundColor") ?? "#242424"
    }
    private func getSelectedFont() -> String {
        let userDefaults = UserDefaults(suiteName: "group.rocketlauncher")
        return userDefaults?.string(forKey: "WidgetFontName") ?? "System"
    }
    
    private func getFontColor() -> String {
        let userDefaults = UserDefaults(suiteName: "group.rocketlauncher")
        return userDefaults?.string(forKey: "WidgetFontColor") ?? "#FFFFFF"
    }
    
    private func getIconsEnabled() -> Bool {
        let userDefaults = UserDefaults(suiteName: "group.rocketlauncher")
        let hasPurchased = userDefaults?.bool(forKey: "HasPurchasedIconFeature") ?? false
        let iconsEnabled = userDefaults?.bool(forKey: "WidgetIconsEnabled") ?? true
        return hasPurchased && iconsEnabled
    }
    
    private func getSpacingAndAlignment() -> (Double, TextAlignment) {
        let userDefaults = UserDefaults(suiteName: "group.rocketlauncher")
        let lineSpacing = userDefaults?.object(forKey: "WidgetLineSpacing") as? Double ?? -0.5
        let alignmentRaw = userDefaults?.string(forKey: "WidgetTextAlignment") ?? "leading"
        let hasPurchased = userDefaults?.bool(forKey: "HasPurchasedTextAlignment") ?? false
        let textAlignment: TextAlignment = {
            if !hasPurchased {
                return .center // Default to center when not purchased
            }
            switch alignmentRaw {
            case "center": return .center
            case "trailing": return .trailing
            default: return .leading
            }
        }()
        return (lineSpacing, textAlignment)
    }
}

// MARK: - Calendar Widget Implementation

struct CalendarEntry: TimelineEntry {
    let date: Date
    let backgroundColor: String
    let fontColor: String
    let highlightColor: String
    let overrideDay: Int? // For dev beta edge day testing
    let isLocked: Bool
    let widgetNumber: Int
    let tapURL: URL? // URL to open when widget is tapped
}

struct CalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry {
        let hasPurchased = hasPurchasedCalendar()
        return CalendarEntry(
            date: Date(),
            backgroundColor: getCalendarBackgroundColor(),
            fontColor: getCalendarFontColor(),
            highlightColor: getCalendarHighlightColor(),
            overrideDay: nil,
            isLocked: !hasPurchased,
            widgetNumber: 1,
            tapURL: getCalendarTapURL()
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> ()) {
        let hasPurchased = hasPurchasedCalendar()
        let entry = CalendarEntry(
            date: Date(),
            backgroundColor: getCalendarBackgroundColor(),
            fontColor: getCalendarFontColor(),
            highlightColor: getCalendarHighlightColor(),
            overrideDay: getEdgeDayIfEnabled(),
            isLocked: !hasPurchased,
            widgetNumber: 1,
            tapURL: getCalendarTapURL()
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> ()) {
        let now = Date()
        let calendar = Calendar.current
        let hasPurchased = hasPurchasedCalendar()
        
        // Create entries for current time and next few hours
        var entries: [CalendarEntry] = []
        
        // Get edge day once for this timeline
        let edgeDay = getEdgeDayIfEnabled()
        let tapURL = getCalendarTapURL()
        
        // Current entry
        let currentEntry = CalendarEntry(
            date: now,
            backgroundColor: getCalendarBackgroundColor(),
            fontColor: getCalendarFontColor(),
            highlightColor: getCalendarHighlightColor(),
            overrideDay: edgeDay,
            isLocked: !hasPurchased,
            widgetNumber: 1,
            tapURL: tapURL
        )
        entries.append(currentEntry)
        
        // Add entries for the next few hours to ensure widget updates regularly
        for hourOffset in 1...6 {
            if let futureDate = calendar.date(byAdding: .hour, value: hourOffset, to: now) {
                let entry = CalendarEntry(
                    date: futureDate,
                    backgroundColor: getCalendarBackgroundColor(),
                    fontColor: getCalendarFontColor(),
                    highlightColor: getCalendarHighlightColor(),
                    overrideDay: edgeDay,
                    isLocked: !hasPurchased,
                    widgetNumber: 1,
                    tapURL: tapURL
                )
                entries.append(entry)
            }
        }
        
        // Schedule the next major update at midnight
        let midnight = calendar.startOfDay(for: now)
        let nextMidnight = calendar.date(byAdding: .day, value: 1, to: midnight)!
        
        // Use .atEnd policy to allow manual refreshes to take effect immediately
        let timeline = Timeline(entries: entries, policy: .after(nextMidnight))
        completion(timeline)
    }
    
    private func hasPurchasedCalendar() -> Bool {
        let userDefaults = UserDefaults(suiteName: "group.rocketlauncher")
        return userDefaults?.bool(forKey: "HasPurchasedCalendar") ?? false
    }
    
    private func getCalendarBackgroundColor() -> String {
        let userDefaults = UserDefaults(suiteName: "group.rocketlauncher")
        return userDefaults?.string(forKey: "WidgetBackgroundColor") ?? "#242424"
    }
    
    private func getCalendarFontColor() -> String {
        let userDefaults = UserDefaults(suiteName: "group.rocketlauncher")
        return userDefaults?.string(forKey: "WidgetFontColor") ?? "#FFFFFF"
    }
    
    private func getCalendarHighlightColor() -> String {
        let userDefaults = UserDefaults(suiteName: "group.rocketlauncher")
        return userDefaults?.string(forKey: "CalendarHighlightColor") ?? "#FF3B30"
    }
    
    private func getCalendarTapURL() -> URL? {
        let userDefaults = UserDefaults(suiteName: "group.rocketlauncher")
        
        // Check if tap is enabled
        guard userDefaults?.bool(forKey: "CalendarWidgetTapEnabled") == true else {
            return nil
        }
        
        // Determine the target scheme
        let targetScheme: String
        
        if userDefaults?.bool(forKey: "CalendarWidgetUseCustomURL") == true {
            // Use custom URL scheme
            if let customURL = userDefaults?.string(forKey: "CalendarWidgetCustomURL"),
               !customURL.isEmpty {
                targetScheme = customURL
            } else {
                return nil
            }
        } else {
            // Default to opening the Calendar app
            targetScheme = "calshow://"
        }
        
        // Route through the main app like app launcher widgets do
        // This ensures proper haptic feedback and URL handling
        if let encodedScheme = targetScheme.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return URL(string: "rocketlauncher://launch?scheme=\(encodedScheme)")
        }
        
        return nil
    }
    
    private func getEdgeDayIfEnabled() -> Int? {
        let userDefaults = UserDefaults(suiteName: "group.rocketlauncher")
        let isEnabled = userDefaults?.bool(forKey: "CalendarEdgeDayTesting") ?? false
        
        guard isEnabled else { return nil }
        
        // Get edge days for current month (only left/right edges)
        let now = Date()
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: now),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return nil
        }
        
        let numberOfDays = range.count
        
        // Only collect days that are on left edge (Sundays) or right edge (Saturdays)
        var edgeDays: [Int] = []
        
        for day in 1...numberOfDays {
            if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                let weekday = calendar.component(.weekday, from: dayDate)
                // Left edge: Sunday (weekday = 1)
                // Right edge: Saturday (weekday = 7)
                if weekday == 1 || weekday == 7 {
                    edgeDays.append(day)
                }
            }
        }
        
        // Pick a random edge day from left or right columns
        return edgeDays.randomElement() ?? 1
    }
}

struct CalendarWidgetView: View {
    let entry: CalendarEntry
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    private var isClearBackground: Bool {
        let hex = entry.backgroundColor.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        return hex == "00000000" || hex.lowercased() == "clear"
    }
    private var isHighlightLight: Bool {
        let hex = entry.highlightColor.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 3:
            r = Double((int >> 8) * 17);
            g = Double((int >> 4 & 0xF) * 17);
            b = Double((int & 0xF) * 17)
        case 6:
            r = Double((int >> 16) & 0xFF);
            g = Double((int >> 8) & 0xFF);
            b = Double(int & 0xFF)
        case 8:
            r = Double((int >> 16) & 0xFF);
            g = Double((int >> 8) & 0xFF);
            b = Double(int & 0xFF)
        default:
            r = 255; g = 255; b = 255
        }
        // Perceived luminance (0..1)
        let luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
        return luminance > 0.7
    }
    
    private var isDisplayZoomed: Bool {
        let screen = UIScreen.main
        return screen.scale != screen.nativeScale || screen.bounds.width <= 375
    }
    
    private func layoutScale(for size: CGSize) -> CGFloat {
        let referenceWidth: CGFloat = 348.0
        let referenceHeight: CGFloat = 162.0
        let widthScale = size.width > 0 ? (size.width / referenceWidth) : (isDisplayZoomed ? 0.85 : 1.0)
        let heightScale = size.height > 0 ? (size.height / referenceHeight) : (isDisplayZoomed ? 0.85 : 1.0)
        return min(1.0, min(widthScale, heightScale))
    }
    
    var body: some View {
        ZStack {
            
            GeometryReader { geo in
                let s = layoutScale(for: geo.size)
                let cellWidth: CGFloat = 21.0 * s
                let headerHeight: CGFloat = 16.0 * s
                let dayCellHeight: CGFloat = 18.5 * s
                let circleSize: CGFloat = 18.5 * s
                let gridSpacing: CGFloat = 1.0 * s
                
                Group {
                    if entry.isLocked {
                        // Locked widget view
                        ZStack {
                            // Blurred placeholder
                            HStack(spacing: 8 * s) {
                                VStack(spacing: 8 * s) {
                                    Text("00")
                                        .font(.system(size: 80 * s, weight: .bold))
                                        .foregroundColor(Color(hex: entry.fontColor))
                                        .opacity(0.3)
                                    Text("Date Placeholder")
                                        .font(.system(size: 14.5 * s, weight: .medium))
                                        .foregroundColor(Color(hex: entry.fontColor))
                                        .opacity(0.3)
                                }
                                .frame(width: 140 * s)
                                Spacer()
                            }
                            .padding(16 * s)
                            .blur(radius: 8)
                            
                            // Lock overlay
                            VStack(spacing: 10 * s) {
                                Text("🔒")
                                    .font(.system(size: 54 * s))
                                Text("Calendar Locked")
                                    .font(.system(size: 16 * s, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Tap to Unlock")
                                    .font(.system(size: 12 * s))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    } else {
                        HStack(spacing: 8 * s) {
                            // Left side - Date information
                            VStack(spacing: 5 * s) {
                                // Large day number - centered and bigger
                                Text(dayString)
                                    .font(.system(size: 80 * s, weight: .bold))
                                    .foregroundColor(Color(hex: entry.fontColor))
                                    .minimumScaleFactor(0.4)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                
                                // Full date in format: Tuesday, 12 August 2025
                                Text(fullDateString)
                                    .font(.system(size: 14.5 * s, weight: .medium))
                                    .foregroundColor(Color(hex: entry.fontColor))
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.75)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                
                                // Day of year
                                Text(dayOfYearString)
                                    .font(.system(size: 12.5 * s, weight: .regular))
                                    .foregroundColor(Color(hex: entry.fontColor).opacity(0.7))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .frame(width: 140 * s)
                            
                            Spacer(minLength: 4 * s) // Push calendar to the right
                            
                            // Right side - Mini calendar
                            VStack(spacing: 2.5 * s) {
                                // Calendar header (S M T W T F S)
                                HStack(spacing: gridSpacing) {
                                    ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                                        Text(day)
                                            .font(.system(size: 11.5 * s, weight: .medium))
                                            .foregroundColor(isWeekend(dayLetter: day) ?
                                                           Color(hex: entry.fontColor).opacity(0.4) : // Weekend days dimmed
                                                           Color(hex: entry.fontColor)) // Weekdays full color
                                            .frame(width: cellWidth, height: headerHeight)
                                    }
                                }
                                
                                // Calendar grid
                                LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: gridSpacing), count: 7), spacing: gridSpacing) {
                                    ForEach(calendarDays.prefix(42), id: \.self) { day in
                                        if day > 0 {
                                            if day == currentDay {
                                                ZStack {
                                                    if #available(iOS 18.0, *) {
                                                        Image(systemName: "circle.fill")
                                                            .resizable()
                                                            .widgetAccentedRenderingMode(.fullColor)
                                                            .foregroundStyle(Color(hex: entry.highlightColor))
                                                            .frame(width: circleSize, height: circleSize)
                                                            .overlay(
                                                                Circle()
                                                                    .stroke(Color.black.opacity(0.15), lineWidth: 0.8 * s)
                                                            )
                                                    } else {
                                                        Circle()
                                                            .fill(Color(hex: entry.highlightColor))
                                                            .frame(width: circleSize, height: circleSize)
                                                            .overlay(
                                                                Circle()
                                                                    .stroke(Color.black.opacity(0.15), lineWidth: 0.8 * s)
                                                            )
                                                    }
                                                    Text("\(day)")
                                                        .font(.system(size: 10.5 * s, weight: .bold))
                                                        .foregroundColor(isHighlightLight ? Color.black.opacity(0.9) : .white)
                                                }
                                                .frame(width: cellWidth, height: dayCellHeight)
                                            } else {
                                                Text("\(day)")
                                                    .font(.system(size: 10.5 * s, weight: .medium))
                                                    .foregroundColor(isWeekend(day: day) ? Color(hex: entry.fontColor).opacity(0.5) : Color(hex: entry.fontColor))
                                                    .frame(width: cellWidth, height: dayCellHeight)
                                            }
                                        } else {
                                            Color.clear
                                                .frame(width: cellWidth, height: dayCellHeight)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16 * s)
                        .padding(.vertical, 10 * s)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var yearMonthString: String {
        dateFormatter.dateFormat = "yyyy.MM"
        return dateFormatter.string(from: entry.date)
    }
    
    private var dayString: String {
        dateFormatter.dateFormat = "dd"
        return dateFormatter.string(from: entry.date)
    }
    
    private var monthDayString: String {
        dateFormatter.dateFormat = "MMMM dd"
        return dateFormatter.string(from: entry.date)
    }
    
    private var dayOfWeekString: String {
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: entry.date)
    }
    
    private var fullDateString: String {
        dateFormatter.dateFormat = "EEEE, dd MMMM yyyy"
        return dateFormatter.string(from: entry.date)
    }
    
    private var dayOfYearString: String {
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: entry.date) ?? 1
        let daysInYear = calendar.range(of: .day, in: .year, for: entry.date)?.count ?? 365
        return "\(dayOfYear)/\(daysInYear)"
    }
    
    private var currentDay: Int {
        // Use override day if dev beta testing is enabled
        if let overrideDay = entry.overrideDay {
            return overrideDay
        }
        return calendar.component(.day, from: entry.date)
    }
    
    private var calendarDays: [Int] {
        guard let range = calendar.range(of: .day, in: .month, for: entry.date),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: entry.date)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let numberOfDays = range.count
        
        var days: [Int] = []
        
        // Add empty days for the beginning of the month
        for _ in 1..<firstWeekday {
            days.append(0)
        }
        
        // Add actual days
        for day in 1...numberOfDays {
            days.append(day)
        }
        
        // Pad to complete weeks (42 total cells = 6 weeks * 7 days)
        while days.count < 42 {
            days.append(0)
        }
        
        return days
    }
    
    private func isWeekend(dayLetter: String) -> Bool {
        return dayLetter == "S" // Both Sunday and Saturday start with S
    }
    
    private func isWeekend(day: Int) -> Bool {
        guard day > 0,
              let date = calendar.date(from: calendar.dateComponents([.year, .month], from: entry.date)),
              let dayDate = calendar.date(byAdding: .day, value: day - 1, to: date) else {
            return false
        }
        
        let weekday = calendar.component(.weekday, from: dayDate)
        return weekday == 1 || weekday == 7 // Sunday = 1, Saturday = 7
    }
}

struct CalendarWidget: Widget {
    let kind: String = "CalendarWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
            CalendarWidgetView(entry: entry)
                .widgetContainerBackgroundModifier(hexColor: entry.backgroundColor)
                .widgetURL(entry.isLocked ? URL(string: "rocketlauncher://purchase?calendar=1") : entry.tapURL)
        }
        .disableContentMarginsIfNeeded()
        .configurationDisplayName("Calendar Widget")
        .description("Displays the current date with a mini monthly calendar.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Day Counter Widget (Left side of calendar)

struct DayCounterWidget: Widget {
    let kind: String = "DayCounterWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
            DayCounterWidgetView(entry: entry)
                .widgetContainerBackgroundModifier(hexColor: entry.backgroundColor)
                .widgetURL(entry.tapURL)
        }
        .disableContentMarginsIfNeeded()
        .configurationDisplayName("Day Counter")
        .description("Displays the current day number, date, and day of year.")
        .supportedFamilies([.systemSmall])
    }
}

struct DayCounterWidgetView: View {
    let entry: CalendarEntry
    
    private let dateFormatter = DateFormatter()
    
    // Detect if iOS Display Zoom is enabled
    private var isDisplayZoomed: Bool {
        let screen = UIScreen.main
        return screen.scale != screen.nativeScale || screen.bounds.width <= 375
    }
    
    private func layoutScale(for size: CGSize) -> CGFloat {
        let referenceSize: CGFloat = 165.0
        let widthScale = size.width > 0 ? (size.width / referenceSize) : (isDisplayZoomed ? 0.86 : 1.0)
        let heightScale = size.height > 0 ? (size.height / referenceSize) : (isDisplayZoomed ? 0.86 : 1.0)
        return min(1.0, min(widthScale, heightScale))
    }
    
    var body: some View {
        ZStack {
            
            GeometryReader { geo in
                let s = layoutScale(for: geo.size)
                
                VStack(spacing: 7.0 * s) {
                    // Large day number - centered and bigger
                    Text(dayString)
                        .font(.system(size: 98.0 * s, weight: .bold))
                        .foregroundColor(Color(hex: entry.fontColor))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Full date in format: Monday, 17 November 2025
                    Text(fullDateString)
                        .font(.system(size: 17.5 * s, weight: .medium))
                        .foregroundColor(Color(hex: entry.fontColor))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Day of year
                    Text(dayOfYearString)
                        .font(.system(size: 15.0 * s, weight: .regular))
                        .foregroundColor(Color(hex: entry.fontColor).opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 12.0 * s)
                .padding(.vertical, 8.0 * s)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            }
        }
    }
    
    private var dayString: String {
        // Use override day if dev beta testing is enabled
        if let overrideDay = entry.overrideDay {
            return String(format: "%02d", overrideDay)
        }
        dateFormatter.dateFormat = "dd"
        return dateFormatter.string(from: entry.date)
    }
    
    private var fullDateString: String {
        dateFormatter.dateFormat = "EEEE, dd MMMM yyyy"
        return dateFormatter.string(from: entry.date)
    }
    
    private var dayOfYearString: String {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: entry.date) ?? 1
        let daysInYear = calendar.range(of: .day, in: .year, for: entry.date)?.count ?? 365
        return "\(dayOfYear)/\(daysInYear)"
    }
}

// MARK: - Calendar Viewer Widget (Right side of calendar)

struct CalendarViewerWidget: Widget {
    let kind: String = "CalendarViewerWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
            CalendarViewerWidgetView(entry: entry)
                .widgetContainerBackgroundModifier(hexColor: entry.backgroundColor)
                .widgetURL(entry.tapURL)
        }
        .disableContentMarginsIfNeeded()
        .configurationDisplayName("Calendar Viewer")
        .description("Displays a mini monthly calendar grid.")
        .supportedFamilies([.systemSmall])
    }
}

struct CalendarViewerWidgetView: View {
    let entry: CalendarEntry
    
    private let calendar = Calendar.current
    
    // Detect if iOS Display Zoom is enabled
    private var isDisplayZoomed: Bool {
        let screen = UIScreen.main
        return screen.scale != screen.nativeScale || screen.bounds.width <= 375
    }
    
    private func layoutScale(for size: CGSize) -> CGFloat {
        let referenceSize: CGFloat = 176.0
        let widthScale = size.width > 0 ? (size.width / referenceSize) : (isDisplayZoomed ? 0.84 : 1.0)
        let heightScale = size.height > 0 ? (size.height / referenceSize) : (isDisplayZoomed ? 0.84 : 1.0)
        return min(1.0, min(widthScale, heightScale))
    }
    
    private var isHighlightLight: Bool {
        let hex = entry.highlightColor.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 3:
            r = Double((int >> 8) * 17);
            g = Double((int >> 4 & 0xF) * 17);
            b = Double((int & 0xF) * 17)
        case 6:
            r = Double((int >> 16) & 0xFF);
            g = Double((int >> 8) & 0xFF);
            b = Double(int & 0xFF)
        case 8:
            r = Double((int >> 16) & 0xFF);
            g = Double((int >> 8) & 0xFF);
            b = Double(int & 0xFF)
        default:
            r = 255; g = 255; b = 255
        }
        let luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
        return luminance > 0.7
    }
    
    var body: some View {
        ZStack {
            
            GeometryReader { geo in
                let s = layoutScale(for: geo.size)
                let headerFontSize: CGFloat = 13.0 * s
                let dayFontSize: CGFloat = 12.0 * s
                let cellWidth: CGFloat = 20.5 * s
                let headerCellHeight: CGFloat = 17.0 * s
                let dayCellHeight: CGFloat = 19.0 * s
                let circleSize: CGFloat = 19.0 * s
                let gridSpacing: CGFloat = 2.5 * s
                
                VStack(spacing: 3.5 * s) {
                    // Calendar header (S M T W T F S)
                    HStack(spacing: gridSpacing) {
                        ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                            Text(day)
                                .font(.system(size: headerFontSize, weight: .medium))
                                .foregroundColor(isWeekend(dayLetter: day) ?
                                               Color(hex: entry.fontColor).opacity(0.4) :
                                               Color(hex: entry.fontColor))
                                .frame(width: cellWidth, height: headerCellHeight)
                        }
                    }
                    
                    // Calendar grid
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: gridSpacing), count: 7), spacing: gridSpacing) {
                        ForEach(calendarDays.prefix(42), id: \.self) { day in
                            if day > 0 {
                                if day == currentDay {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: entry.highlightColor))
                                            .frame(width: circleSize, height: circleSize)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.black.opacity(0.15), lineWidth: 0.6 * s)
                                            )
                                        Text("\(day)")
                                            .font(.system(size: dayFontSize, weight: .bold))
                                            .foregroundColor(isHighlightLight ? Color.black.opacity(0.9) : .white)
                                    }
                                    .frame(width: cellWidth, height: dayCellHeight)
                                } else {
                                    Text("\(day)")
                                        .font(.system(size: dayFontSize, weight: .medium))
                                        .foregroundColor(isWeekend(day: day) ? Color(hex: entry.fontColor).opacity(0.5) : Color(hex: entry.fontColor))
                                        .frame(width: cellWidth, height: dayCellHeight)
                                }
                            } else {
                                Color.clear
                                    .frame(width: cellWidth, height: dayCellHeight)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8.0 * s)
                .padding(.vertical, 6.0 * s)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            }
        }
    }
    
    private var currentDay: Int {
        // Use override day if dev beta testing is enabled
        if let overrideDay = entry.overrideDay {
            return overrideDay
        }
        return calendar.component(.day, from: entry.date)
    }
    
    private var calendarDays: [Int] {
        guard let range = calendar.range(of: .day, in: .month, for: entry.date),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: entry.date)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let numberOfDays = range.count
        
        var days: [Int] = []
        
        // Add empty days for the beginning of the month
        for _ in 1..<firstWeekday {
            days.append(0)
        }
        
        // Add actual days
        for day in 1...numberOfDays {
            days.append(day)
        }
        
        // Pad to complete weeks (42 total cells = 6 weeks * 7 days)
        while days.count < 42 {
            days.append(0)
        }
        
        return days
    }
    
    private func isWeekend(dayLetter: String) -> Bool {
        return dayLetter == "S" // Both Sunday and Saturday start with S
    }
    
    private func isWeekend(day: Int) -> Bool {
        guard day > 0,
              let date = calendar.date(from: calendar.dateComponents([.year, .month], from: entry.date)),
              let dayDate = calendar.date(byAdding: .day, value: day - 1, to: date) else {
            return false
        }
        
        let weekday = calendar.component(.weekday, from: dayDate)
        return weekday == 1 || weekday == 7 // Sunday = 1, Saturday = 7
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
