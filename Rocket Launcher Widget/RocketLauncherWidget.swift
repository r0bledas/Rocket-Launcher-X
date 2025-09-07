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
}

struct LauncherEntry: TimelineEntry {
    let date: Date
    let apps: [App]
    let backgroundColor: String
    let fontColor: String
    let lineSpacing: Double
    let textAlignment: TextAlignment
    let fontName: String
    struct App: Hashable {
        let name: String
        let urlScheme: String
    }
}

struct LauncherProvider: TimelineProvider {
    func placeholder(in context: Context) -> LauncherEntry {
        LauncherEntry(date: Date(), apps: [], backgroundColor: getBackgroundColor(), fontColor: getFontColor(), lineSpacing: 0, textAlignment: .leading, fontName: getSelectedFont())
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
        let userDefaults = UserDefaults(suiteName: "group.com.Robledas.rocketlauncher.Rocket-Launcher")
        var apps: [LauncherEntry.App] = []
        if let data = userDefaults?.data(forKey: "AppLaunchers"),
           let launchers = try? JSONDecoder().decode([AppLauncher].self, from: data) {
            apps = launchers.prefix(8).map { LauncherEntry.App(name: $0.name, urlScheme: $0.urlScheme) }
        }
        let color = userDefaults?.string(forKey: "WidgetBackgroundColor") ?? "#242424"
        let fontColor = userDefaults?.string(forKey: "WidgetFontColor") ?? "#FFFFFF"
        let lineSpacing = userDefaults?.object(forKey: "WidgetLineSpacing") as? Double ?? 0
        let alignmentRaw = userDefaults?.string(forKey: "WidgetTextAlignment") ?? "leading"
        let textAlignment: TextAlignment = {
            switch alignmentRaw {
            case "center": return .center
            case "trailing": return .trailing
            default: return .leading
            }
        }()
        return LauncherEntry(date: Date(), apps: apps, backgroundColor: color, fontColor: fontColor, lineSpacing: lineSpacing, textAlignment: textAlignment, fontName: getSelectedFont())
    }
    private func getBackgroundColor() -> String {
        let userDefaults = UserDefaults(suiteName: "group.com.Robledas.rocketlauncher.Rocket-Launcher")
        return userDefaults?.string(forKey: "WidgetBackgroundColor") ?? "#242424"
    }
    private func getSelectedFont() -> String {
        let userDefaults = UserDefaults(suiteName: "group.com.Robledas.rocketlauncher.Rocket-Launcher")
        return userDefaults?.string(forKey: "WidgetFontName") ?? "System"
    }
    
    private func getFontColor() -> String {
        let userDefaults = UserDefaults(suiteName: "group.com.Robledas.rocketlauncher.Rocket-Launcher")
        return userDefaults?.string(forKey: "WidgetFontColor") ?? "#FFFFFF"
    }
}

struct LauncherWidgetEntryView: View {
    let entry: LauncherEntry
    
    private var backgroundView: some View {
            Color(hex: entry.backgroundColor)
                .ignoresSafeArea()
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
                        let textView = Text(app.name)
                                    .font(getCustomFont(name: entry.fontName, size: 36, weight: .bold))
                                    .foregroundColor(Color(hex: entry.fontColor))
                                    .frame(maxWidth: .infinity, alignment: frameAlignmentFor(entry.textAlignment))
                                    .multilineTextAlignment(entry.textAlignment)
                                    .padding(.vertical, 2)
                        textView
                            }
                            .buttonStyle(PlainButtonStyle())

                        }
                    }
                }
                .padding(24)
    }
    
    var body: some View {
        ZStack {
            backgroundView
            if entry.apps.isEmpty || entry.apps.allSatisfy({ $0.name.isEmpty }) {
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
    let userDefaults = UserDefaults(suiteName: "group.com.Robledas.rocketlauncher.Rocket-Launcher")
    var apps: [LauncherEntry.App] = []
    if let data = userDefaults?.data(forKey: "AppLaunchers"),
       let launchers = try? JSONDecoder().decode([AppLauncher].self, from: data) {
        let start = widgetIndex * 8
        let end = min(start + 8, launchers.count)
        if start < end {
            apps = launchers[start..<end].map { LauncherEntry.App(name: $0.name, urlScheme: $0.urlScheme) }
        }
    }
    return apps
}

struct RocketLauncherWidget: Widget {
    let kind: String = "RocketLauncherWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LauncherProvider()) { entry in
            if #available(iOS 17.0, *) {
                LauncherWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color(hex: entry.backgroundColor)
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
                        Color(hex: entry.backgroundColor)
                    }
            } else {
                LauncherWidgetEntryView(entry: entry)
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
                        Color(hex: entry.backgroundColor)
                    }
            } else {
                LauncherWidgetEntryView(entry: entry)
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
                        Color(hex: entry.backgroundColor)
                    }
            } else {
                LauncherWidgetEntryView(entry: entry)
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
                        Color(hex: entry.backgroundColor)
                    }
            } else {
                LauncherWidgetEntryView(entry: entry)
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
        return LauncherEntry(date: Date(), apps: loadAppsForWidget(widgetIndex: widgetIndex), backgroundColor: getBackgroundColor(), fontColor: getFontColor(), lineSpacing: lineSpacing, textAlignment: textAlignment, fontName: getSelectedFont())
    }
    func getSnapshot(in context: Context, completion: @escaping (LauncherEntry) -> ()) {
        let (lineSpacing, textAlignment) = getSpacingAndAlignment()
        let entry = LauncherEntry(date: Date(), apps: loadAppsForWidget(widgetIndex: widgetIndex), backgroundColor: getBackgroundColor(), fontColor: getFontColor(), lineSpacing: lineSpacing, textAlignment: textAlignment, fontName: getSelectedFont())
        completion(entry)
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<LauncherEntry>) -> ()) {
        let (lineSpacing, textAlignment) = getSpacingAndAlignment()
        let entry = LauncherEntry(date: Date(), apps: loadAppsForWidget(widgetIndex: widgetIndex), backgroundColor: getBackgroundColor(), fontColor: getFontColor(), lineSpacing: lineSpacing, textAlignment: textAlignment, fontName: getSelectedFont())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    private func getBackgroundColor() -> String {
        let userDefaults = UserDefaults(suiteName: "group.com.Robledas.rocketlauncher.Rocket-Launcher")
        return userDefaults?.string(forKey: "WidgetBackgroundColor") ?? "#242424"
    }
    private func getSelectedFont() -> String {
        let userDefaults = UserDefaults(suiteName: "group.com.Robledas.rocketlauncher.Rocket-Launcher")
        return userDefaults?.string(forKey: "WidgetFontName") ?? "System"
    }
    
    private func getFontColor() -> String {
        let userDefaults = UserDefaults(suiteName: "group.com.Robledas.rocketlauncher.Rocket-Launcher")
        return userDefaults?.string(forKey: "WidgetFontColor") ?? "#FFFFFF"
    }
    
    private func getSpacingAndAlignment() -> (Double, TextAlignment) {
        let userDefaults = UserDefaults(suiteName: "group.com.Robledas.rocketlauncher.Rocket-Launcher")
        let lineSpacing = userDefaults?.object(forKey: "WidgetLineSpacing") as? Double ?? 0
        let alignmentRaw = userDefaults?.string(forKey: "WidgetTextAlignment") ?? "leading"
        let textAlignment: TextAlignment = {
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
}

struct CalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(
            date: Date(),
            backgroundColor: getCalendarBackgroundColor(),
            fontColor: getCalendarFontColor(),
            highlightColor: getCalendarHighlightColor()
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> ()) {
        let entry = CalendarEntry(
            date: Date(),
            backgroundColor: getCalendarBackgroundColor(),
            fontColor: getCalendarFontColor(),
            highlightColor: getCalendarHighlightColor()
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> ()) {
        let now = Date()
        let calendar = Calendar.current
        
        // Create entries for current time and next few hours
        var entries: [CalendarEntry] = []
        
        // Current entry
        let currentEntry = CalendarEntry(
            date: now,
            backgroundColor: getCalendarBackgroundColor(),
            fontColor: getCalendarFontColor(),
            highlightColor: getCalendarHighlightColor()
        )
        entries.append(currentEntry)
        
        // Add entries for the next few hours to ensure widget updates regularly
        for hourOffset in 1...6 {
            if let futureDate = calendar.date(byAdding: .hour, value: hourOffset, to: now) {
                let entry = CalendarEntry(
                    date: futureDate,
                    backgroundColor: getCalendarBackgroundColor(),
                    fontColor: getCalendarFontColor(),
                    highlightColor: getCalendarHighlightColor()
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
    
    private func getCalendarBackgroundColor() -> String {
        let userDefaults = UserDefaults(suiteName: "group.com.Robledas.rocketlauncher.Rocket-Launcher")
        return userDefaults?.string(forKey: "WidgetBackgroundColor") ?? "#242424"
    }
    
    private func getCalendarFontColor() -> String {
        let userDefaults = UserDefaults(suiteName: "group.com.Robledas.rocketlauncher.Rocket-Launcher")
        return userDefaults?.string(forKey: "WidgetFontColor") ?? "#FFFFFF"
    }
    
    private func getCalendarHighlightColor() -> String {
        let userDefaults = UserDefaults(suiteName: "group.com.Robledas.rocketlauncher.Rocket-Launcher")
        return userDefaults?.string(forKey: "CalendarHighlightColor") ?? "#FF3B30"
    }
}

struct CalendarWidgetView: View {
    let entry: CalendarEntry
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    var body: some View {
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
                            ZStack {
                                if day == currentDay {
                                    Circle()
                                        .fill(Color(hex: entry.highlightColor))
                                        .frame(width: 20, height: 20)
                                }
                                
                                Text("\(day)")
                                    .font(.system(size: 11, weight: day == currentDay ? .bold : .medium))
                                    .foregroundColor(day == currentDay ? .white :
                                                   (isWeekend(day: day) ? Color(hex: entry.fontColor).opacity(0.5) : Color(hex: entry.fontColor)))
                            }
                            .frame(width: 22, height: 20)
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
        .background(Color(hex: entry.backgroundColor))
        .clipped()
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
        calendar.component(.day, from: entry.date)
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
                        Color(hex: entry.backgroundColor)
                    }
            } else {
                CalendarWidgetView(entry: entry)
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
    CalendarEntry(date: Date(), backgroundColor: "#242424", fontColor: "#FFFFFF", highlightColor: "#FF3B30")
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
