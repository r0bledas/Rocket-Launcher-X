//
//  RocketLauncherWidget.swift
//  Rocket Launcher Widget
//
//  Created by Raudel Alejandro on 19-07-2025.
//

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
        return screen.scale != screen.nativeScale
    }
    
    // Dynamic sizes based on display zoom (9.5% reduction when zoomed)
    private var appFontSize: CGFloat {
        isDisplayZoomed ? 32.58 : 36
    }
    
    private var iconSize: CGFloat {
        isDisplayZoomed ? 27.15 : 30
    }
    
    private var iconCornerRadius: CGFloat {
        isDisplayZoomed ? 5.8825 : 6.5
    }
    
    private var horizontalPadding: CGFloat {
        isDisplayZoomed ? 21.72 : 24
    }
    
    private var iconSpacing: CGFloat {
        isDisplayZoomed ? 7.24 : 8
    }
    
    private var verticalPadding: CGFloat {
        isDisplayZoomed ? 1.3575 : 1.5
    }
    
    private var leadingAdjustment: CGFloat {
        isDisplayZoomed ? -13.575 : -15
    }
    
    private var emptyStateView: some View {
                Text("👻")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.5))
    }
    
    private var appButtonView: some View {
                VStack(alignment: horizontalAlignmentFor(entry.textAlignment), spacing: entry.lineSpacing) {
            ForEach(Array(entry.apps.prefix(8).enumerated()), id: \.offset) { idx, app in
                        if !app.name.isEmpty && !app.urlScheme.isEmpty {
                            Link(destination: URL(string: "rocketlauncher://launch?scheme=\(app.urlScheme.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!) {
                                HStack(spacing: iconSpacing) {
                                     if entry.iconsEnabled, (app.showIcon ?? false), let image = loadIconImage(fileName: app.iconFileName) {
                                         Image(uiImage: image)
                                             .resizable()
                                             .interpolation(.high)
                                             .aspectRatio(contentMode: .fit)
                                             .frame(width: iconSize, height: iconSize)
                                             .clipShape(RoundedRectangle(cornerRadius: iconCornerRadius))
                                     }
                                    Text(app.name)
                                        .font(getCustomFont(name: entry.fontName, size: appFontSize, weight: .bold))
                                        .foregroundColor(Color(hex: entry.fontColor))
                                        .frame(maxWidth: .infinity, alignment: frameAlignmentFor(entry.textAlignment))
                                        .multilineTextAlignment(entry.textAlignment)
                                        .padding(.vertical, verticalPadding)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())

                        }
                    }
                }
                .padding(horizontalPadding)
                .padding(.leading, (entry.textAlignment == .leading && entry.iconsEnabled && entry.apps.contains { $0.showIcon ?? false }) ? leadingAdjustment : 0)
    }
    
    var body: some View {
        ZStack {
            if entry.isLocked {
                // Locked widget view
                ZStack {
                    // Blurred placeholder content
                    VStack(alignment: .leading, spacing: entry.lineSpacing) {
                        ForEach(0..<8) { _ in
                            Text("App Name")
                                .font(getCustomFont(name: entry.fontName, size: appFontSize, weight: .bold))
                                .foregroundColor(Color(hex: entry.fontColor))
                                .opacity(0.3)
                                .padding(.vertical, verticalPadding)
                        }
                    }
                    .padding(horizontalPadding)
                    .blur(radius: 8)
                    
                    // Lock overlay
                    VStack(spacing: 12) {
                        Text("🔒")
                            .font(.system(size: 80))
                        
                        Text("Widget #\(entry.widgetNumber) Locked")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Tap to Unlock")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }
            } else if entry.apps.isEmpty || entry.apps.allSatisfy({ $0.name.isEmpty }) {
                emptyStateView
            } else {
                appButtonView
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

struct RocketLauncherWidget: Widget {
    let kind: String = "RocketLauncherWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LauncherProvider()) { entry in
            if #available(iOS 17.0, *) {
                LauncherWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        let hex = entry.backgroundColor.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                        if hex == "00000000" || hex.lowercased() == "clear" {
                            Color.black.opacity(0.95)
                        } else {
                            Color(hex: entry.backgroundColor)
                        }
                    }
            } else {
                LauncherWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Widget #1")
        .description("Display and launch your favorite apps (Widget #1).")
        .supportedFamilies([.systemLarge])
    }
}

struct RocketLauncherWidget2: Widget {
    let kind: String = "RocketLauncherWidget2"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CustomLauncherProvider(widgetIndex: 1)) { entry in
            if #available(iOS 17.0, *) {
                LauncherWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        let hex = entry.backgroundColor.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                        if hex == "00000000" || hex.lowercased() == "clear" {
                            Color.black.opacity(0.95)
                        } else {
                            Color(hex: entry.backgroundColor)
                        }
                    }
                    .widgetURL(entry.isLocked ? URL(string: "rocketlauncher://purchase?widget=2") : nil)
            } else {
                LauncherWidgetEntryView(entry: entry)
                    .widgetURL(entry.isLocked ? URL(string: "rocketlauncher://purchase?widget=2") : nil)
            }
        }
        .configurationDisplayName("Widget #2")
        .description("Display and launch your favorite apps (Widget #2).")
        .supportedFamilies([.systemLarge])
    }
}

struct RocketLauncherWidget3: Widget {
    let kind: String = "RocketLauncherWidget3"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CustomLauncherProvider(widgetIndex: 2)) { entry in
            if #available(iOS 17.0, *) {
                LauncherWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        let hex = entry.backgroundColor.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                        if hex == "00000000" || hex.lowercased() == "clear" {
                            Color.black.opacity(0.95)
                        } else {
                            Color(hex: entry.backgroundColor)
                        }
                    }
                    .widgetURL(entry.isLocked ? URL(string: "rocketlauncher://purchase?widget=3") : nil)
            } else {
                LauncherWidgetEntryView(entry: entry)
                    .widgetURL(entry.isLocked ? URL(string: "rocketlauncher://purchase?widget=3") : nil)
            }
        }
        .configurationDisplayName("Widget #3")
        .description("Display and launch your favorite apps (Widget #3).")
        .supportedFamilies([.systemLarge])
    }
}

struct RocketLauncherWidget4: Widget {
    let kind: String = "RocketLauncherWidget4"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CustomLauncherProvider(widgetIndex: 3)) { entry in
            if #available(iOS 17.0, *) {
                LauncherWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        let hex = entry.backgroundColor.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                        if hex == "00000000" || hex.lowercased() == "clear" {
                            Color.black.opacity(0.95)
                        } else {
                            Color(hex: entry.backgroundColor)
                        }
                    }
                    .widgetURL(entry.isLocked ? URL(string: "rocketlauncher://purchase?widget=4") : nil)
            } else {
                LauncherWidgetEntryView(entry: entry)
                    .widgetURL(entry.isLocked ? URL(string: "rocketlauncher://purchase?widget=4") : nil)
            }
        }
        .configurationDisplayName("Widget #4")
        .description("Display and launch your favorite apps (Widget #4).")
        .supportedFamilies([.systemLarge])
    }
}

struct RocketLauncherWidget5: Widget {
    let kind: String = "RocketLauncherWidget5"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CustomLauncherProvider(widgetIndex: 4)) { entry in
            if #available(iOS 17.0, *) {
                LauncherWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        let hex = entry.backgroundColor.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                        if hex == "00000000" || hex.lowercased() == "clear" {
                            Color.black.opacity(0.95)
                        } else {
                            Color(hex: entry.backgroundColor)
                        }
                    }
                    .widgetURL(entry.isLocked ? URL(string: "rocketlauncher://purchase?widget=5") : nil)
            } else {
                LauncherWidgetEntryView(entry: entry)
                    .widgetURL(entry.isLocked ? URL(string: "rocketlauncher://purchase?widget=5") : nil)
            }
        }
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
        return userDefaults?.bool(forKey: "HasPurchasedExtraWidgets") ?? false
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
            widgetNumber: 1
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
            widgetNumber: 1
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
        
        // Current entry
        let currentEntry = CalendarEntry(
            date: now,
            backgroundColor: getCalendarBackgroundColor(),
            fontColor: getCalendarFontColor(),
            highlightColor: getCalendarHighlightColor(),
            overrideDay: edgeDay,
            isLocked: !hasPurchased,
            widgetNumber: 1
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
                    widgetNumber: 1
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
    
    var body: some View {
        ZStack {
            if entry.isLocked {
                // Locked widget view
                ZStack {
                    // Blurred placeholder
                    HStack(spacing: 8) {
                        VStack(spacing: 10) {
                            Text("00")
                                .font(.system(size: 90, weight: .bold))
                                .foregroundColor(Color(hex: entry.fontColor))
                                .opacity(0.3)
                            Text("Date Placeholder")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(hex: entry.fontColor))
                                .opacity(0.3)
                        }
                        .frame(width: 150)
                        Spacer()
                    }
                    .padding()
                    .blur(radius: 8)
                    
                    // Lock overlay
                    VStack(spacing: 12) {
                        Text("🔒")
                            .font(.system(size: 60))
                        Text("Calendar Locked")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text("Tap to Unlock")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            } else {
        HStack(spacing: 8) {
            // Left side - Date information
            VStack(spacing: 10) {
                // Large day number - centered and bigger
                Text(dayString)
                    .font(.system(size: 90, weight: .bold))
                    .foregroundColor(Color(hex: entry.fontColor))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                // Full date in format: Tuesday, 12 August 2025
                Text(fullDateString)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: entry.fontColor))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                // Day of year
                Text(dayOfYearString)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(hex: entry.fontColor).opacity(0.7))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(width: 150)
            .padding(.leading, 10)
            
            Spacer() // Add spacer to push calendar to the right
            
            // Right side - Mini calendar
            VStack(spacing: 3) {
                // Calendar header (S M T W T F S)
                HStack(spacing: 1) {
                    ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                        Text(day)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isWeekend(dayLetter: day) ?
                                           Color(hex: entry.fontColor).opacity(0.4) : // Weekend days dimmed
                                           Color(hex: entry.fontColor)) // Weekdays full color
                            .frame(width: 22, height: 17)
                    }
                }
                
                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(22), spacing: 1), count: 7), spacing: 1) {
                    ForEach(calendarDays.prefix(42), id: \.self) { day in
                        if day > 0 {
                            if day == currentDay {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: entry.highlightColor))
                                        .frame(width: 20, height: 20)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black.opacity(0.15), lineWidth: 0.8)
                                        )
                                    Text("\(day)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(isHighlightLight ? Color.black.opacity(0.9) : .white)
                                }
                                .frame(width: 22, height: 20)
                            } else {
                                Text("\(day)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(isWeekend(day: day) ? Color(hex: entry.fontColor).opacity(0.5) : Color(hex: entry.fontColor))
                                    .frame(width: 22, height: 20)
                            }
                        } else {
                            Color.clear
                                .frame(width: 22, height: 20)
                        }
                    }
                }
            }
            .padding(.trailing, 16)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            if #available(iOS 17.0, *) {
                CalendarWidgetView(entry: entry)
                    .containerBackground(for: .widget) {
                        let hex = entry.backgroundColor.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                        if hex == "00000000" || hex.lowercased() == "clear" {
                            Color.black.opacity(0.95)
                        } else {
                            Color(hex: entry.backgroundColor)
                        }
                    }
                    .widgetURL(entry.isLocked ? URL(string: "rocketlauncher://purchase?calendar=1") : nil)
            } else {
                CalendarWidgetView(entry: entry)
                    .widgetURL(entry.isLocked ? URL(string: "rocketlauncher://purchase?calendar=1") : nil)
            }
        }
        .configurationDisplayName("Calendar Widget")
        .description("Displays the current date with a mini monthly calendar.")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    CalendarWidget()
} timeline: {
    CalendarEntry(date: Date(), backgroundColor: "#242424", fontColor: "#FFFFFF", highlightColor: "#FF3B30", overrideDay: nil, isLocked: false, widgetNumber: 1)
}

// MARK: - Day Counter Widget (Left side of calendar)

struct DayCounterWidget: Widget {
    let kind: String = "DayCounterWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
            if #available(iOS 17.0, *) {
                DayCounterWidgetView(entry: entry)
                    .containerBackground(for: .widget) {
                        let hex = entry.backgroundColor.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                        if hex == "00000000" || hex.lowercased() == "clear" {
                            Color.black.opacity(0.95)
                        } else {
                            Color(hex: entry.backgroundColor)
                        }
                    }
            } else {
                DayCounterWidgetView(entry: entry)
            }
        }
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
        return screen.scale != screen.nativeScale
    }
    
    // Dynamic sizes based on display zoom (4% increase when zoomed, tuned standard sizes)
    private var dayNumberFontSize: CGFloat {
        isDisplayZoomed ? 93.6 : 108
    }
    
    private var dateFontSize: CGFloat {
        // Keep original visual size as requested
        isDisplayZoomed ? 16.64 : 19.2
    }
    
    private var dayOfYearFontSize: CGFloat {
        isDisplayZoomed ? 14.56 : 16.8
    }
    
    private var verticalSpacing: CGFloat {
        // Slightly tighter spacing to give lines more vertical room overall
        isDisplayZoomed ? 7.8 : 9.0
    }
    
    private var horizontalPadding: CGFloat {
        // Slightly reduced horizontal padding to gain a bit more width
        isDisplayZoomed ? 11.5 : 13.2
    }
    
    private var verticalPadding: CGFloat {
        isDisplayZoomed ? 7.8 : 8.8
    }
    
    var body: some View {
        VStack(spacing: verticalSpacing) {
            // Large day number - centered and bigger
            Text(dayString)
                .font(.system(size: dayNumberFontSize, weight: .bold))
                .foregroundColor(Color(hex: entry.fontColor))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Full date in format: Monday, 17 November 2025
            Text(fullDateString)
                .font(.system(size: dateFontSize, weight: .medium))
                .foregroundColor(Color(hex: entry.fontColor))
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Day of year
            Text(dayOfYearString)
                .font(.system(size: dayOfYearFontSize, weight: .regular))
                .foregroundColor(Color(hex: entry.fontColor).opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            if #available(iOS 17.0, *) {
                CalendarViewerWidgetView(entry: entry)
                    .containerBackground(for: .widget) {
                        let hex = entry.backgroundColor.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                        if hex == "00000000" || hex.lowercased() == "clear" {
                            Color.black.opacity(0.95)
                        } else {
                            Color(hex: entry.backgroundColor)
                        }
                    }
            } else {
                CalendarViewerWidgetView(entry: entry)
            }
        }
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
        return screen.scale != screen.nativeScale
    }
    
    // Dynamic sizes based on display zoom (16% reduction when zoomed)
    private var headerFontSize: CGFloat {
        isDisplayZoomed ? 11.76 : 13.72
    }
    
    private var dayFontSize: CGFloat {
        isDisplayZoomed ? 10.92 : 12.74
    }
    
    private var cellWidth: CGFloat {
        isDisplayZoomed ? 18.48 : 21.56
    }
    
    private var headerCellHeight: CGFloat {
        isDisplayZoomed ? 15.12 : 17.64
    }
    
    private var dayCellHeight: CGFloat {
        isDisplayZoomed ? 16.8 : 19.6
    }
    
    private var circleSize: CGFloat {
        isDisplayZoomed ? 16.8 : 19.6
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
        VStack(spacing: 4) {
            // Calendar header (S M T W T F S)
            HStack(spacing: 3) {
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
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: 3), count: 7), spacing: 3) {
                ForEach(calendarDays.prefix(42), id: \.self) { day in
                    if day > 0 {
                        if day == currentDay {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: entry.highlightColor))
                                    .frame(width: circleSize, height: circleSize)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black.opacity(0.15), lineWidth: 0.6)
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
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

// MARK: - Flip Clock Widget

struct FlipClockEntry: TimelineEntry {
    let date: Date
    let backgroundColor: String
    let fontColor: String
    let highlightColor: String
}

struct FlipClockProvider: TimelineProvider {
    func placeholder(in context: Context) -> FlipClockEntry {
        FlipClockEntry(
            date: Date(),
            backgroundColor: getFlipClockBackgroundColor(),
            fontColor: getFlipClockFontColor(),
            highlightColor: getFlipClockHighlightColor()
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (FlipClockEntry) -> ()) {
        let entry = FlipClockEntry(
            date: Date(),
            backgroundColor: getFlipClockBackgroundColor(),
            fontColor: getFlipClockFontColor(),
            highlightColor: getFlipClockHighlightColor()
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<FlipClockEntry>) -> ()) {
        let now = Date()
        let calendar = Calendar.current
        
        // Create entries for every 0.5 second for the next minute
        var entries: [FlipClockEntry] = []
        
        for secondOffset in 0..<120 { // 60 seconds * 2 = 0.5s intervals
            let timeOffset = Double(secondOffset) * 0.5
            if let futureDate = calendar.date(byAdding: .second, value: Int(timeOffset), to: now) {
                let entry = FlipClockEntry(
                    date: futureDate,
                    backgroundColor: getFlipClockBackgroundColor(),
                    fontColor: getFlipClockFontColor(),
                    highlightColor: getFlipClockHighlightColor()
                )
                entries.append(entry)
            }
        }
        
        // Schedule the next major update at the next minute
        let currentMinute = calendar.dateInterval(of: .minute, for: now)?.start ?? now
        let nextMinute = calendar.date(byAdding: .minute, value: 1, to: currentMinute)!
        let timeline = Timeline(entries: entries, policy: .after(nextMinute))
        completion(timeline)
    }
    
    private func getFlipClockBackgroundColor() -> String {
        let userDefaults = UserDefaults(suiteName: "group.rocketlauncher")
        return userDefaults?.string(forKey: "WidgetBackgroundColor") ?? "#242424"
    }
    
    private func getFlipClockFontColor() -> String {
        let userDefaults = UserDefaults(suiteName: "group.rocketlauncher")
        return userDefaults?.string(forKey: "WidgetFontColor") ?? "#FFFFFF"
    }
    
    private func getFlipClockHighlightColor() -> String {
        let userDefaults = UserDefaults(suiteName: "group.rocketlauncher")
        return userDefaults?.string(forKey: "CalendarHighlightColor") ?? "#FF3B30"
    }
}

struct FlipClockWidget: Widget {
    let kind: String = "FlipClockWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FlipClockProvider()) { entry in
            if #available(iOS 17.0, *) {
                FlipClockWidgetView(entry: entry)
                    .containerBackground(for: .widget) {
                        let hex = entry.backgroundColor.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                        if hex == "00000000" || hex.lowercased() == "clear" {
                            Color.black.opacity(0.95)
                        } else {
                            Color(hex: entry.backgroundColor)
                        }
                    }
            } else {
                FlipClockWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Flip Clock")
        .description("Displays the current time with Apple-style flip animation.")
        .supportedFamilies([.systemSmall])
    }
}

struct FlipClockWidgetView: View {
    let entry: FlipClockEntry
    @State private var previousTime = ""

    var body: some View {
        GeometryReader { geo in
            let currentTime = timeString(from: entry.date)
            let components = currentTime.split(separator: ":")
            let hours = components.first ?? "00"
            let minutes = components.count > 1 ? components[1] : "00"
            let dynamicFontSize = min(geo.size.width, geo.size.height) * 0.4

            // Compute blinking colon based on seconds
            let seconds = Calendar.current.component(.second, from: entry.date)
            let showColon = seconds % 2 == 0

            HStack(spacing: 4) {
                FlipText(text: String(hours), color: entry.fontColor, fontSize: dynamicFontSize)

                Text(":")
                    .font(.system(size: dynamicFontSize, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: entry.fontColor))
                    .opacity(showColon ? 1 : 0)

                FlipText(text: String(minutes), color: entry.fontColor, fontSize: dynamicFontSize)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .onChange(of: entry.date) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    previousTime = currentTime
                }
            }
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct FlipText: View {
    let text: String
    let color: String
    var fontSize: CGFloat

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .medium, design: .monospaced))
            .foregroundColor(Color(hex: color))
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .rotation3DEffect(.degrees(10), axis: (x: 1, y: 0, z: 0))
            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
