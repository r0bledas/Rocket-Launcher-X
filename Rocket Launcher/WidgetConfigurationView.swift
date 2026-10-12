//
//  WidgetConfigurationView.swift
//  Rocket Launcher
//
//  Created by Raudel Alejandro on 19-07-2025.
//

import SwiftUI
import WidgetKit
import UIKit

enum PreviewWidgetType: String, CaseIterable, Identifiable {
    case launcher = "Launcher"
    case calendar = "Calendar"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .launcher: return "app.fill"
        case .calendar: return "calendar"
        }
    }
}

// MARK: - Widget Configuration View
struct WidgetConfigurationView: View {
    @ObservedObject var store: AppLauncherStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var backgroundColor: Color = Color(hex: "#242424")
    @State private var customHexInput: String = "#242424"
    @State private var selectedAlignment: TextAlignmentOption = .leading
    @State private var iconsEnabled: Bool = true
    @State private var selectedPreviewType: PreviewWidgetType = .launcher
    @State private var didJustApplyWidgets = false
    
    @AppStorage("HasPurchasedIconFeature", store: UserDefaults(suiteName: appGroupID)) private var hasPurchasedIconFeature: Bool = false
    @AppStorage("HasPurchasedTextAlignment", store: UserDefaults(suiteName: appGroupID)) private var hasPurchasedTextAlignment: Bool = false
    
    @State private var showIconPurchaseAlert = false
    @State private var showAlignmentPurchaseAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Section 1: Live Widget Preview Header
                        livePreviewSection
                        
                        // Section 2: Custom Color & Hex Input
                        customColorSection
                        
                        // Section 3: Text Alignment
                        textAlignmentSection
                        
                        // Section 4: App Icons Toggle
                        iconsToggleSection
                        
                        // Section 5: Apply to Widgets Action
                        applyButtonSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Widget Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        HapticsHelper.impact(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.blue)
                    .accessibilityLabel("Cancel")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticsHelper.impact(.light)
                        applyColorToWidgets()
                        WidgetCenter.shared.reloadAllTimelines()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.blue)
                    .accessibilityLabel("Apply and close")
                }
            }
        }
        .onAppear {
            loadSettings()
        }
    }
    
    // MARK: - Display Zoom & Widget Metrics (1:1 with RocketLauncherWidget.swift)
    private var isDisplayZoomed: Bool {
        let screen = UIScreen.main
        return screen.scale != screen.nativeScale || screen.bounds.width <= 375
    }
    
    private func launcherLayoutScale(for size: CGSize) -> CGFloat {
        let extraSpacing = max(0, CGFloat(widgetLineSpacing) * 7.0)
        let referenceWidth: CGFloat = 355.0
        let referenceHeight: CGFloat = 390.0 + extraSpacing
        let widthScale = size.width > 0 ? (size.width / referenceWidth) : (isDisplayZoomed ? 0.82 : 1.0)
        let heightScale = size.height > 0 ? (size.height / referenceHeight) : (isDisplayZoomed ? 0.82 : 1.0)
        return min(1.0, min(widthScale, heightScale))
    }
    
    private func calendarLayoutScale(for size: CGSize) -> CGFloat {
        let referenceWidth: CGFloat = 348.0
        let referenceHeight: CGFloat = 162.0
        let widthScale = size.width > 0 ? (size.width / referenceWidth) : (isDisplayZoomed ? 0.85 : 1.0)
        let heightScale = size.height > 0 ? (size.height / referenceHeight) : (isDisplayZoomed ? 0.85 : 1.0)
        return min(1.0, min(widthScale, heightScale))
    }
    
    private var widgetFontColor: String {
        UserDefaults(suiteName: appGroupID)?.string(forKey: "WidgetFontColor") ?? "#FFFFFF"
    }
    
    private var widgetFontName: String {
        UserDefaults(suiteName: appGroupID)?.string(forKey: "WidgetFontName") ?? "System"
    }
    
    private var widgetLineSpacing: Double {
        UserDefaults(suiteName: appGroupID)?.object(forKey: "WidgetLineSpacing") as? Double ?? -0.5
    }
    
    private var calendarHighlightColor: String {
        UserDefaults(suiteName: appGroupID)?.string(forKey: "CalendarHighlightColor") ?? "#FF3B30"
    }
    
    private var effectiveTextAlignment: TextAlignment {
        if !hasPurchasedTextAlignment {
            return .center
        }
        return selectedAlignment.textAlignment
    }
    
    private var effectiveIconsEnabled: Bool {
        hasPurchasedIconFeature && iconsEnabled
    }
    
    private var previewSize: CGSize {
        let maxAvailableWidth = max(280, UIScreen.main.bounds.width - 36)
        switch selectedPreviewType {
        case .launcher:
            let baseW: CGFloat = isDisplayZoomed ? 306 : 338
            let baseH: CGFloat = isDisplayZoomed ? 316 : 354
            let w = min(baseW, maxAvailableWidth)
            let h = baseH * (w / baseW)
            return CGSize(width: w, height: h)
        case .calendar:
            let baseW: CGFloat = isDisplayZoomed ? 306 : 338
            let baseH: CGFloat = isDisplayZoomed ? 148 : 158
            let w = min(baseW, maxAvailableWidth)
            let h = baseH * (w / baseW)
            return CGSize(width: w, height: h)
        }
    }
    
    // MARK: - Live Preview Section
    private var livePreviewSection: some View {
        VStack(spacing: 12) {
            // Header with widget type picker
            HStack {
                Text("LIVE PREVIEW")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .tracking(1)
                
                Spacer()
                
                Picker("Preview Type", selection: $selectedPreviewType) {
                    ForEach(PreviewWidgetType.allCases) { type in
                        Label(type.rawValue, systemImage: type.iconName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 240)
            }
            
            // Exact iOS Home Screen Widget Frame
            ZStack {
                // Static Background Color (1:1 with StaticWidgetBackground)
                let hex = customHexInput.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                if hex == "00000000" || hex.lowercased() == "clear" {
                    Color.black.opacity(0.95)
                } else {
                    backgroundColor
                }
                
                // Content based on selected widget (1:1 with RocketLauncherWidget.swift)
                switch selectedPreviewType {
                case .launcher:
                    launcherPreviewContent
                case .calendar:
                    calendarPreviewContent
                }
            }
            .frame(width: previewSize.width, height: previewSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 8)
            .frame(maxWidth: .infinity)
            .animation(.easeInOut(duration: 0.25), value: selectedPreviewType)
            .animation(.easeInOut(duration: 0.2), value: backgroundColor)
        }
    }
    
    // MARK: - Launcher Widget Live Preview (1:1 with LauncherWidgetEntryView)
    private var launcherPreviewContent: some View {
        GeometryReader { geo in
            let scale = launcherLayoutScale(for: geo.size)
            let appFontSize: CGFloat = 36.0 * scale
            let iconSize: CGFloat = 30.0 * scale
            let iconCornerRadius: CGFloat = 6.5 * scale
            let horizontalPadding: CGFloat = 24.0 * scale
            let iconSpacing: CGFloat = 8.0 * scale
            let verticalPadding: CGFloat = 1.5 * scale
            let leadingAdjustment: CGFloat = -15.0 * scale
            let systemContentMargin: CGFloat = 16.0 * scale
            let scaledLineSpacing: CGFloat = CGFloat(widgetLineSpacing) * scale
            let apps = Array(store.launchers.prefix(8))
            let alignment = effectiveTextAlignment
            
            Group {
                if apps.isEmpty || apps.allSatisfy({ $0.name.isEmpty }) {
                    Text("👻")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.5))
                } else {
                    VStack(alignment: horizontalAlignmentFor(alignment), spacing: scaledLineSpacing) {
                        ForEach(Array(apps.enumerated()), id: \.offset) { _, app in
                            if !app.name.isEmpty && !app.urlScheme.isEmpty {
                                HStack(spacing: iconSpacing) {
                                    if effectiveIconsEnabled, (app.showIcon ?? false), let image = loadIconPreview(for: app) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .interpolation(.high)
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: iconSize, height: iconSize)
                                            .clipShape(RoundedRectangle(cornerRadius: iconCornerRadius))
                                    }
                                    Text(app.name)
                                        .font(getCustomFont(name: widgetFontName, size: appFontSize, weight: .bold))
                                        .foregroundColor(Color(hex: widgetFontColor))
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: frameAlignmentFor(alignment))
                                        .multilineTextAlignment(alignment)
                                        .padding(.vertical, verticalPadding)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.leading, (alignment == .leading && effectiveIconsEnabled && apps.contains { $0.showIcon ?? false }) ? leadingAdjustment : 0)
                    .padding(.horizontal, systemContentMargin)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
    }
    
    // MARK: - Calendar Widget Live Preview (1:1 with CalendarWidgetView)
    private var calendarPreviewContent: some View {
        let now = Date()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        formatter.dateFormat = "dd"
        let dayString = formatter.string(from: now)
        
        formatter.dateFormat = "EEEE, dd MMMM yyyy"
        let fullDateString = formatter.string(from: now)
        
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        let daysInYear = calendar.range(of: .day, in: .year, for: now)?.count ?? 365
        let dayOfYearString = "\(dayOfYear)/\(daysInYear)"
        
        let currentDay = calendar.component(.day, from: now)
        let days = computeCalendarDays(for: now)
        let isLightHighlight = isHighlightColorLight(calendarHighlightColor)
        
        return GeometryReader { geo in
            let s = calendarLayoutScale(for: geo.size)
            let cellWidth: CGFloat = 21.0 * s
            let headerHeight: CGFloat = 16.0 * s
            let dayCellHeight: CGFloat = 18.5 * s
            let circleSize: CGFloat = 18.5 * s
            let gridSpacing: CGFloat = 1.0 * s
            
            HStack(spacing: 8 * s) {
                // Left side - Date information
                VStack(spacing: 5 * s) {
                    Text(dayString)
                        .font(.system(size: 80 * s, weight: .bold))
                        .foregroundColor(Color(hex: widgetFontColor))
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text(fullDateString)
                        .font(.system(size: 14.5 * s, weight: .medium))
                        .foregroundColor(Color(hex: widgetFontColor))
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text(dayOfYearString)
                        .font(.system(size: 12.5 * s, weight: .regular))
                        .foregroundColor(Color(hex: widgetFontColor).opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .frame(width: 140 * s)
                
                Spacer(minLength: 4 * s)
                
                // Right side - Mini calendar
                VStack(spacing: 2.5 * s) {
                    HStack(spacing: gridSpacing) {
                        ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                            Text(day)
                                .font(.system(size: 11.5 * s, weight: .medium))
                                .foregroundColor(day == "S" ?
                                                 Color(hex: widgetFontColor).opacity(0.4) :
                                                 Color(hex: widgetFontColor))
                                .frame(width: 21 * s, height: headerHeight)
                        }
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: gridSpacing), count: 7), spacing: gridSpacing) {
                        ForEach(Array(days.prefix(42).enumerated()), id: \.offset) { _, day in
                            if day > 0 {
                                if day == currentDay {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: calendarHighlightColor))
                                            .frame(width: circleSize, height: circleSize)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.black.opacity(0.15), lineWidth: 0.8 * s)
                                            )
                                        Text("\(day)")
                                            .font(.system(size: 10.5 * s, weight: .bold))
                                            .foregroundColor(isLightHighlight ? Color.black.opacity(0.9) : .white)
                                    }
                                    .frame(width: cellWidth, height: dayCellHeight)
                                } else {
                                    Text("\(day)")
                                        .font(.system(size: 10.5 * s, weight: .medium))
                                        .foregroundColor(isWeekendDay(day, in: now) ? Color(hex: widgetFontColor).opacity(0.5) : Color(hex: widgetFontColor))
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
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
    }
    
    // MARK: - Widget Preview Helpers (1:1 with RocketLauncherWidget.swift)
    private func getCustomFont(name: String, size: CGFloat, weight: Font.Weight) -> Font {
        if name == "System" {
            return .system(size: size, weight: weight)
        } else if let customFont = UIFont(name: name, size: size) {
            return Font(customFont as CTFont)
        } else {
            return .system(size: size, weight: weight)
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
    
    private func computeCalendarDays(for date: Date) -> [Int] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return []
        }
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let numberOfDays = range.count
        var days: [Int] = []
        for _ in 1..<firstWeekday {
            days.append(0)
        }
        for day in 1...numberOfDays {
            days.append(day)
        }
        while days.count < 42 {
            days.append(0)
        }
        return days
    }
    
    private func isWeekendDay(_ day: Int, in date: Date) -> Bool {
        let calendar = Calendar.current
        guard day > 0,
              let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let dayDate = calendar.date(byAdding: .day, value: day - 1, to: monthStart) else {
            return false
        }
        let weekday = calendar.component(.weekday, from: dayDate)
        return weekday == 1 || weekday == 7
    }
    
    private func isHighlightColorLight(_ hexColor: String) -> Bool {
        let hex = hexColor.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 3:
            r = Double((int >> 8) * 17)
            g = Double((int >> 4 & 0xF) * 17)
            b = Double((int & 0xF) * 17)
        case 6, 8:
            r = Double((int >> 16) & 0xFF)
            g = Double((int >> 8) & 0xFF)
            b = Double(int & 0xFF)
        default:
            r = 255; g = 255; b = 255
        }
        let luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
        return luminance > 0.7
    }
    
    // MARK: - Section 2: Custom Color & Hex Input
    private var customColorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "paintbrush.fill")
                    .foregroundColor(.purple)
                Text("CUSTOM COLOR & HEX")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .tracking(1)
            }

            // Native system color picker with a visible label
            ColorPicker("Background Color", selection: $backgroundColor, supportsOpacity: false)
                .font(.subheadline)
                .tint(.purple)
                .onChange(of: backgroundColor) { _, newColor in
                    customHexInput = newColor.toHex()
                }

            Divider()
                .overlay(Color.white.opacity(0.1))

            // Hex entry with live swatch + reset
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(backgroundColor)
                    .frame(width: 34, height: 34)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .accessibilityHidden(true)

                HStack(spacing: 2) {
                    Text("#")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.5))
                    TextField("RRGGBB", text: hexBinding)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .keyboardType(.asciiCapable)
                        .accessibilityLabel("Hex color value")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )

                Button("Reset") {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    backgroundColor = Color(hex: "#242424")
                    customHexInput = "#242424"
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.white)
            }

            Text("Enter a 3- or 6-digit hex code, or use the color picker above.")
                .font(.caption2)
                .foregroundColor(Color.white.opacity(0.5))
        }
        .padding(16)
        .background(Color.gray.opacity(0.12))
        .cornerRadius(16)
    }

    /// Two-way binding that keeps the hex field and the color swatch in sync.
    private var hexBinding: Binding<String> {
        Binding(
            get: {
                customHexInput
                    .trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                    .uppercased()
            },
            set: { newValue in
                let cleaned = String(newValue
                    .trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                    .uppercased()
                    .prefix(6))
                customHexInput = "#\(cleaned)"
                if cleaned.count == 3 || cleaned.count == 6 {
                    backgroundColor = Color(hex: cleaned)
                }
            }
        )
    }
    
    // MARK: - Section 4: Text Alignment
    private var textAlignmentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.orange)
                Text("TEXT ALIGNMENT")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .tracking(1)
                
                if !hasPurchasedTextAlignment {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            
            Picker("Alignment", selection: $selectedAlignment) {
                Text(TextAlignmentOption.leading.label).tag(TextAlignmentOption.leading)
                Text(TextAlignmentOption.center.label).tag(TextAlignmentOption.center)
                Text(TextAlignmentOption.trailing.label).tag(TextAlignmentOption.trailing)
            }
            .pickerStyle(.segmented)
            .disabled(!hasPurchasedTextAlignment || iconsEnabled)
            .opacity((hasPurchasedTextAlignment && !iconsEnabled) ? 1.0 : 0.5)
            .onChange(of: selectedAlignment) { _, _ in
                HapticsHelper.selection()
            }
            
            if iconsEnabled {
                Text("Text alignment is locked to Left when icons are enabled.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            if !hasPurchasedTextAlignment {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showAlignmentPurchaseAlert = true
                }) {
                    Text("Unlock Text Alignment (~$20 MXN)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.12))
        .cornerRadius(16)
        .alert("Purchase Required", isPresented: $showAlignmentPurchaseAlert) {
            Button("OK") { }
        } message: {
            Text("This is a purchase simulator. In the production app, this would open the App Store purchase flow for Text Alignment (~$20 MXN).")
        }
    }
    
    // MARK: - Section 5: App Icons Toggle
    private var iconsToggleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Toggle(isOn: Binding(
                    get: { iconsEnabled && hasPurchasedIconFeature },
                    set: { newValue in
                        if hasPurchasedIconFeature {
                            HapticsHelper.impact(.light)
                            iconsEnabled = newValue
                            if newValue {
                                store.bulkFetchIcons()
                                selectedAlignment = .leading
                            }
                        } else {
                            HapticsHelper.warning()
                            showIconPurchaseAlert = true
                        }
                    }
                )) {
                    HStack(spacing: 8) {
                        Image(systemName: "questionmark.square")
                            .foregroundColor(.green)
                        Text("Show Icons In Widgets")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .green))
                
                if !hasPurchasedIconFeature {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
            
            if !hasPurchasedIconFeature {
                Button(action: {
                    HapticsHelper.impact(.medium)
                    showIconPurchaseAlert = true
                }) {
                    HStack {
                        Image(systemName: "cart.fill")
                        Text("Unlock Icon Feature (~$19 MXN)")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.orange)
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.12))
        .cornerRadius(16)
        .alert("Purchase Required", isPresented: $showIconPurchaseAlert) {
            Button("OK") { }
        } message: {
            Text("This is a purchase simulator. In the production app, this would open the App Store purchase flow for the Icon Feature (~$19 MXN).")
        }
    }
    
    // MARK: - Section 6: Apply Button
    private var applyButtonSection: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            applyColorToWidgets()
            WidgetCenter.shared.reloadAllTimelines()
            withTransaction(Transaction(animation: nil)) {
                didJustApplyWidgets = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withTransaction(Transaction(animation: nil)) {
                    didJustApplyWidgets = false
                }
            }
        }) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: didJustApplyWidgets ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                    .font(.title2)
                Text(didJustApplyWidgets ? "Applied Successfully! ✅" : "Apply to Widgets")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(didJustApplyWidgets ? Color.green : Color.blue)
            .cornerRadius(14)
            .shadow(color: (didJustApplyWidgets ? Color.green : Color.blue).opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Helpers & Persistence
    private var isContrastDark: Bool {
        let uiColor = UIColor(backgroundColor)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance < 0.65
    }
    
    private func applyColorToWidgets() {
        let userDefaults = UserDefaults(suiteName: appGroupID)
        let hexColor = backgroundColor.toHex()
        userDefaults?.set(hexColor, forKey: "WidgetBackgroundColor")
        userDefaults?.set(selectedAlignment.rawValue, forKey: "WidgetTextAlignment")
        userDefaults?.set(iconsEnabled, forKey: "WidgetIconsEnabled")
        userDefaults?.synchronize()
    }
    
    private func loadSettings() {
        let userDefaults = UserDefaults(suiteName: appGroupID)
        let savedBackgroundColor = userDefaults?.string(forKey: "WidgetBackgroundColor") ?? "#242424"
        backgroundColor = Color(hex: savedBackgroundColor)
        customHexInput = savedBackgroundColor
        if let alignmentRaw = userDefaults?.string(forKey: "WidgetTextAlignment"),
           let option = TextAlignmentOption(rawValue: alignmentRaw) {
            selectedAlignment = option
        } else {
            selectedAlignment = .leading
        }
        iconsEnabled = userDefaults?.bool(forKey: "WidgetIconsEnabled") ?? true
    }
}

// MARK: - Extension for Alignment Helpers
extension TextAlignmentOption {
    var textAlignment: TextAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
    
    var frameAlignment: Alignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
    
    var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}
