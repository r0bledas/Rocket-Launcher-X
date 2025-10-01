//
//  ContentView.swift
//  Rocket Launcher
//
//  Created by Raudel Alejandro on 19-07-2025.
// hello

import SwiftUI
import WidgetKit
import UIKit
import ActivityKit
import ActivityKit
import CoreMotion
import UniformTypeIdentifiers
import AudioToolbox

// Centralized App Group ID
let appGroupID = "group.com.Robledas.rocketlauncher.Rocket-Launcher"

// MARK: - Shake Detection
class ShakeDetector: ObservableObject {
    @Published var isShakeDetected = false
    private let motionManager = CMMotionManager()
    private let queue: OperationQueue = {
        let q = OperationQueue()
        q.qualityOfService = .userInitiated
        return q
    }()
    private var shakeThreshold: Double = 2.5
    private var lastTriggerAt: Date = .distantPast
    private let cooldown: TimeInterval = 2.5
    
    init() {
        startShakeDetection()
    }
    
    private func startShakeDetection() {
        guard motionManager.isAccelerometerAvailable else { return }
        
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, error in
            guard let self = self, let data = data, error == nil else { return }
            
            let acceleration = sqrt(pow(data.acceleration.x, 2) +
                                  pow(data.acceleration.y, 2) +
                                  pow(data.acceleration.z, 2))
            
            if acceleration > self.shakeThreshold && Date().timeIntervalSince(self.lastTriggerAt) > self.cooldown {
                self.lastTriggerAt = Date()
                self.triggerShake()
            }
        }
    }
    
    private func triggerShake() {
        DispatchQueue.main.async {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            self.isShakeDetected = true
            
            // Auto-hide after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.isShakeDetected = false
            }
        }
    }
    
    func hideSettingsIcon() {
        isShakeDetected = false
    }
    
    deinit {
        motionManager.stopAccelerometerUpdates()
    }
}

// MARK: - Extensions and Types

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

extension UIColor {
    convenience init?(hex: String) {
        let r, g, b, a: CGFloat
        
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            
            if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                    b = CGFloat(hexNumber & 0x0000ff) / 255
                    a = 1.0
                    
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        
        return nil
    }
}

// MARK: - Text Alignment Options

enum TextAlignmentOption: String, CaseIterable, Identifiable {
    case leading = "leading"
    case center = "center"
    case trailing = "trailing"
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .leading: return "Left"
        case .center: return "Center"
        case .trailing: return "Right"
        }
    }
}

// MARK: - Icon Fetch Source Options

enum IconFetchSourceOption: String, CaseIterable, Identifiable {
    case itunes = "itunes"
    case iconfinder = "iconfinder"
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .itunes: return "Apple"
        case .iconfinder: return "Iconfinder"
        }
    }
}

// MARK: - App Launcher Models

struct AppLauncher: Identifiable, Codable {
    let id: Int
    var name: String
    var urlScheme: String
	var iconFileName: String? // stored in App Group container under /icons
	var showIcon: Bool? // optional flag to enable/disable icon rendering
    
	init(id: Int, name: String = "", urlScheme: String = "", iconFileName: String? = nil, showIcon: Bool? = false) {
        self.id = id
        self.name = name
        self.urlScheme = urlScheme
		self.iconFileName = iconFileName
		self.showIcon = showIcon
    }
}

class AppLauncherStore: ObservableObject {
    @Published var launchers: [AppLauncher] = []
    
    private let userDefaults = UserDefaults(suiteName: appGroupID)
    
    init() {
        load()
    }
    
    func load() {
        if let data = userDefaults?.data(forKey: "AppLaunchers"),
           let decodedLaunchers = try? JSONDecoder().decode([AppLauncher].self, from: data) {
            launchers = decodedLaunchers
        } else {
            // Initialize with 40 empty launchers (5 widgets × 8 slots each)
            launchers = (0..<40).map { AppLauncher(id: $0) }
        }
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(launchers) {
            userDefaults?.set(encoded, forKey: "AppLaunchers")
        }
    }
}

// MARK: - Haptics Helper

struct HapticsHelper {
    static func playLaunchHaptic() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    
    // Added this method from the duplicate URLHandler structure
    static func handleURLLaunch() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
}

// MARK: - Helper Functions

private func refreshAllWidgets() {
    WidgetCenter.shared.reloadAllTimelines()
}

struct ContentView: View {
    @State private var showingWidgetSetup = false
    @State private var showingWidgetConfiguration = false
    @State private var showingWidgetLaunchersConfig = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var showBlackout = false
    @State private var blackoutHideWorkItem: DispatchWorkItem? = nil
    @State private var didJustRefreshWidgets = false
    @StateObject private var appLauncherStore = AppLauncherStore()
    // Splash overlay state
    @State private var showSplash = true
    // Shake detection for settings
    @StateObject private var shakeDetector = ShakeDetector()
    @State private var showingSettings = false
    // Settings button control
    @AppStorage("AlwaysShowSettingsButton", store: UserDefaults(suiteName: appGroupID)) private var alwaysShowSettingsButton: Bool = false
    // Page swiper state
    @State private var selectedPage = 0
    
    // MultiTimeX Timer States
    @State private var targetTime = Date()
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isRunning = false
    @State private var initialTimeInterval: TimeInterval = 0
    @State private var currentTime = Date()
    @State private var showingCompletionAlert = false
    @State private var selectedDay = 0 // 0 for today, 1 for tomorrow
    @State private var liveActivity: Activity<MultiTimeXAttributes>? = nil
    
    var progress: Double {
        guard initialTimeInterval > 0 else { return 0 }
        return 1 - (timeRemaining / initialTimeInterval)
    }
    
    // Computed property to check if selected time is valid (in the future)
    private var isSelectedTimeValid: Bool {
        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: targetTime)
        
        if selectedDay == 1 { // If tomorrow is selected
            if let today = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
                let tomorrowComponents = Calendar.current.dateComponents([.year, .month, .day], from: today)
                components.year = tomorrowComponents.year
                components.month = tomorrowComponents.month
                components.day = tomorrowComponents.day
            }
        } else { // If today is selected
            let todayComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.year = todayComponents.year
            components.month = todayComponents.month
            components.day = todayComponents.day
        }
        
        if let adjustedTargetTime = Calendar.current.date(from: components) {
            return adjustedTargetTime.timeIntervalSinceNow > 0
        }
        return false
    }
    
    var body: some View {
        ZStack {
            // Black background to appear black when launched from widgets
            Color.black
                .ignoresSafeArea(.all, edges: .all)
            
            TabView(selection: $selectedPage) {
                // Main Page (0)
                mainView
                    .tag(0)
                
                // Configuration Page (1)
                configurationView
                    .tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea(.all, edges: .all)
            
            // Page indicator dots at the bottom
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<2, id: \.self) { index in
                        Circle()
                            .fill(selectedPage == index ? Color.white : Color.white.opacity(0.4))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: selectedPage)
                    }
                }
                .padding(.bottom, 20)
            }
            
            // Blackout overlay
            if showBlackout {
                Color.black
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(100)
            }
            if showSplash {
                Color.black.ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showingWidgetSetup) {
            WidgetSetupView()
        }
        .sheet(isPresented: $showingWidgetConfiguration) {
            WidgetConfigurationView()
        }
        .sheet(isPresented: $showingWidgetLaunchersConfig) {
            WidgetLaunchersConfigView(store: appLauncherStore)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase != .active {
                blackoutHideWorkItem?.cancel()
                withAnimation(.linear(duration: 0.08)) {
                    showBlackout = true
                }
            } else {
                // Delay hiding the blackout overlay by 0.5s
                blackoutHideWorkItem?.cancel()
                let workItem = DispatchWorkItem {
                    withAnimation(.linear(duration: 0.08)) {
                        showBlackout = false
                    }
                }
                blackoutHideWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
            }
        }
        .onAppear {
            // Only show splash on cold launch
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showSplash = false
            }
        }
    }
    
    // MARK: - Main View
    private var mainView: some View {
        ZStack {
            VStack(spacing: 20) {
                Image(systemName: "rocket")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                
                Text("Rocket Launcher")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(spacing: 12) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showingWidgetConfiguration = true
                    }) {
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title2)
                        Text("Configure Widget")
                            .font(.headline)
                        }
                            .foregroundColor(.white)
                            .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showingWidgetLaunchersConfig = true
                    }) {
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Add Apps")
                            .font(.headline)
                    }
                            .foregroundColor(.white)
                            .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.purple)
                            .cornerRadius(10)
                    }

                Button(action: {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        refreshAllWidgets()
                        withTransaction(Transaction(animation: nil)) {
                            didJustRefreshWidgets = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withTransaction(Transaction(animation: nil)) {
                                didJustRefreshWidgets = false
                            }
                        }
                }) {
                        HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.title2)
                            Text(didJustRefreshWidgets ? "Widgets Refreshed ✅" : "Refresh All Widgets")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange)
                    .cornerRadius(12)
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                    )

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showingWidgetSetup = true
                    }) {
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "questionmark.circle")
                                .font(.title2)
                            Text("Widget Setup Guide")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(10)
                    }
                    
                    // Centered swipe hint
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Text("Swipe left for MultiTimeX")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Image(systemName: "arrow.left")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 40)
            }
            
            // Settings button overlay - positioned at bottom center without affecting other elements
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if alwaysShowSettingsButton || shakeDetector.isShakeDetected {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showingSettings = true
                            shakeDetector.hideSettingsIcon()
                        }) {
                            Image(systemName: "gear")
                                .font(.title)
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 60, height: 60)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .transition(.scale.combined(with: .opacity))
                        .animation(.bouncy(duration: 0.6), value: alwaysShowSettingsButton || shakeDetector.isShakeDetected)
                    }
                    Spacer()
                }
                .padding(.bottom, 80) // Position above page indicators
            }
        }
    }
    
    // MARK: - Configuration View (MultiTimeX)
    private var configurationView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Header hidden while running to avoid duplicate titles in landscape
                if !isRunning {
                    HStack {
                        Spacer()
                        
                        Text("MultiTimeX")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                }
                
                if isRunning {
                    GeometryReader { proxy in
                        let isLandscape = proxy.size.width > proxy.size.height
                        let portraitBaseFont: CGFloat = 94.0
                        let dynamicFontSize = isLandscape ? portraitBaseFont * 1.5 : portraitBaseFont

                        ZStack {
                            // Centered timer content
                            VStack(spacing: 4) {
                                Spacer()
                                Text(timeString(from: timeRemaining))
                                    .font(.system(size: dynamicFontSize, weight: .bold))
                                    .foregroundColor(timeRemaining > 0 ? .white : .red)
                                    .minimumScaleFactor(0.4)
                                    .contentTransition(.numericText())
                                    .animation(.smooth, value: timeRemaining)
                                    .lineLimit(1)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)

                                Text("until \(timeFormatter.string(from: targetTime))")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)

                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .foregroundColor(.gray.opacity(0.3))

                                        Rectangle()
                                            .foregroundColor(timeRemaining > 0 ? .green : .red)
                                            .frame(width: geometry.size.width * progress)
                                            .animation(.smooth(duration: 0.3), value: progress)
                                    }
                                }
                                .frame(height: 15)
                                .cornerRadius(8)
                                .padding(.horizontal, 40)

                                Text("\(Int(progress * 100))%")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                    .contentTransition(.numericText())
                                    .animation(.smooth, value: progress)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                            // Compact Stop button at top-right
                            VStack {
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        stopTimer()
                                        triggerMultiTimeXHapticFeedback()
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "stop.fill")
                                            Text("Stop")
                                                .fontWeight(.semibold)
                                        }
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color.red)
                                        .cornerRadius(10)
                                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                                    }
                                }
                                .padding(.top, proxy.safeAreaInsets.top + 12)
                                .padding(.trailing, 30)
                                Spacer()
                            }
                            .transition(.move(edge: .top))
                            .animation(.smooth(duration: 0.25), value: isRunning)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.bottom, proxy.safeAreaInsets.bottom + 16)
                    }
                } else {
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 25) {
                            Text("Select Target Time")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Picker("Day", selection: $selectedDay) {
                                Text("Today").tag(0)
                                Text("Tomorrow").tag(1)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 40)
                            
                            DatePicker("Target Time",
                                     selection: $targetTime,
                                     displayedComponents: [.hourAndMinute])
                                .labelsHidden()
                                .datePickerStyle(.wheel)
                                .frame(maxWidth: .infinity)
                                .frame(height: 150)
                                .padding(.horizontal, 20)
                            
                            Button(action: {
                                if isSelectedTimeValid {
                                    startTimer()
                                    triggerMultiTimeXHapticFeedback()
                                } else {
                                    // Negative haptic feedback for invalid selection
                                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                                }
                            }) {
                                Text("Start Timer")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isSelectedTimeValid ? Color.green : Color.gray)
                                    .cornerRadius(10)
                                    .animation(.easeInOut(duration: 0.2), value: isSelectedTimeValid)
                            }
                            .padding(.horizontal, 40)
                            .disabled(!isSelectedTimeValid)
                        }
                        .padding(.vertical, 20)
                        
                        Spacer()
                    }
                }
                
                Text("Made by Ra-Rauw!")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
            }
            .alert("Time's Up!", isPresented: $showingCompletionAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }
    
    // MARK: - MultiTimeX Timer Functions
    private func startTimer() {
        // Adjust target time based on selected day
        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: targetTime)
        if selectedDay == 1 { // If tomorrow is selected
            if let today = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
                let tomorrowComponents = Calendar.current.dateComponents([.year, .month, .day], from: today)
                components.year = tomorrowComponents.year
                components.month = tomorrowComponents.month
                components.day = tomorrowComponents.day
            }
        } else { // If today is selected
            let todayComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.year = todayComponents.year
            components.month = todayComponents.month
            components.day = todayComponents.day
        }
        
        if let adjustedTargetTime = Calendar.current.date(from: components) {
            // Only start if the target time is in the future
            if adjustedTargetTime.timeIntervalSinceNow > 0 {
                targetTime = adjustedTargetTime
                timeRemaining = targetTime.timeIntervalSinceNow
                initialTimeInterval = timeRemaining
                isRunning = true
                startLiveActivity(endDate: targetTime)
                currentTime = Date()
                
                let updateInterval = 0.1
                
                timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
                    withAnimation {
                        timeRemaining = targetTime.timeIntervalSinceNow
                        currentTime = Date()
                        
                        if timeRemaining <= 0 {
                            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                            stopTimer()
                        }
                        updateLiveActivityProgress()
                    }
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        endLiveActivity()
        
        if timeRemaining <= 0 {
            showingCompletionAlert = true
        }
    }

    // MARK: - Live Activity helpers
    private func startLiveActivity(endDate: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let initial = MultiTimeXAttributes.ContentState(endDate: endDate, percentComplete: 0)
        do {
            let activity = try Activity<MultiTimeXAttributes>.request(
                attributes: MultiTimeXAttributes(),
                content: ActivityContent(state: initial, staleDate: nil),
                pushType: nil
            )
            liveActivity = activity
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    private func updateLiveActivityProgress() {
        guard let activity = liveActivity else { return }
        let total = max(1, initialTimeInterval)
        let done = max(0, total - max(0, timeRemaining))
        let pct = min(1.0, max(0.0, done / total))
        let state = MultiTimeXAttributes.ContentState(endDate: targetTime, percentComplete: pct)
        Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
    }

    private func endLiveActivity() {
        guard let activity = liveActivity else { return }
        let final = MultiTimeXAttributes.ContentState(endDate: Date(), percentComplete: 1.0)
        Task { await activity.end(ActivityContent(state: final, staleDate: nil), dismissalPolicy: .immediate) }
        liveActivity = nil
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let absInterval = abs(timeInterval)
        let hours = Int(absInterval) / 3600
        let minutes = Int(absInterval) / 60 % 60
        let seconds = Int(absInterval) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter
    }()
    
    private func triggerMultiTimeXHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    // Removed loadSettings() in favor of @AppStorage
}

// MARK: - Widget Configuration View
struct WidgetConfigurationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var backgroundColor = "#242424"
    @State private var redComponent: Double = 36
    @State private var greenComponent: Double = 36
    @State private var blueComponent: Double = 36
    @State private var customHexInput = "#242424"
    // For slider haptics
    @State private var lastRed: Double = 36
    @State private var lastGreen: Double = 36
    @State private var lastBlue: Double = 36
    @State private var didJustApplyWidgets = false
	@State private var selectedAlignment: TextAlignmentOption = .leading
	@State private var iconsEnabled: Bool = true
    @State private var iconFetchSource: IconFetchSourceOption = .itunes
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Widget Background Color Preview
                        VStack(spacing: 12) {
                            Text("Widget Background Color")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: backgroundColor))
                                .frame(height: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray, lineWidth: 2)
                                )
                                .shadow(radius: 10)
                        }
                        .padding()
                        
                        // RGB Controls
                        VStack(spacing: 16) {
                            Text("RGB Controls")
                                .font(.headline)
                                .foregroundColor(.white)
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Red: \(Int(redComponent))")
                                        .foregroundColor(.white)
                                        .frame(width: 80, alignment: .leading)
                                    Slider(value: $redComponent, in: 0...255, step: 1)
                                        .tint(.red)
                                        .onChange(of: redComponent) { old, new in
                                            updateHexFromRGB()
                                            if Int(new) != Int(lastRed) {
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                lastRed = new
                                            }
                                        }
                                }
                                HStack {
                                    Text("Green: \(Int(greenComponent))")
                                        .foregroundColor(.white)
                                        .frame(width: 80, alignment: .leading)
                                    Slider(value: $greenComponent, in: 0...255, step: 1)
                                        .tint(.green)
                                        .onChange(of: greenComponent) { old, new in
                                            updateHexFromRGB()
                                            if Int(new) != Int(lastGreen) {
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                lastGreen = new
                                            }
                                        }
                                }
                                HStack {
                                    Text("Blue: \(Int(blueComponent))")
                                        .foregroundColor(.white)
                                        .frame(width: 80, alignment: .leading)
                                    Slider(value: $blueComponent, in: 0...255, step: 1)
                                        .tint(.blue)
                                        .onChange(of: blueComponent) { old, new in
                                            updateHexFromRGB()
                                            if Int(new) != Int(lastBlue) {
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                lastBlue = new
                                            }
                                        }
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                        }
                        
                        // Custom Hex Input
                        VStack(spacing: 12) {
                            Text("Custom Hex Color")
                                .font(.headline)
                                .foregroundColor(.white)
                            HStack {
                                Text("#")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 8)
                                TextField("Enter hex color", text: $customHexInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: customHexInput) { _, newValue in
                                        let sanitized = sanitizeHexInput(newValue)
                                        if isValidHex(sanitized) {
                                            backgroundColor = "#" + sanitized
                                            updateRGBFromHex()
                                        }
                                        customHexInput = sanitized
                                    }
                                Button(action: {
                                    let sanitized = sanitizeHexInput(customHexInput)
                                    if isValidHex(sanitized) {
                                        backgroundColor = "#" + sanitized
                                        updateRGBFromHex()
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                }) {
                                    Text("Apply")
                                }
                                .disabled(!isValidHex(sanitizeHexInput(customHexInput)))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(isValidHex(sanitizeHexInput(customHexInput)) ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)

						// Text Alignment
						VStack(spacing: 12) {
							Text("Text Alignment")
								.font(.headline)
								.foregroundColor(.white)
							Picker("Alignment", selection: $selectedAlignment) {
								Text(TextAlignmentOption.leading.label).tag(TextAlignmentOption.leading)
								Text(TextAlignmentOption.center.label).tag(TextAlignmentOption.center)
								Text(TextAlignmentOption.trailing.label).tag(TextAlignmentOption.trailing)
							}
							.pickerStyle(.segmented)
						}
						.padding()
						.background(Color.gray.opacity(0.2))
						.cornerRadius(12)
                        
						// Global Icons Toggle
						VStack(spacing: 12) {
							Toggle("Show Icons in Widgets", isOn: $iconsEnabled)
								.toggleStyle(SwitchToggleStyle(tint: .green))
								.foregroundColor(.white)
						}
						.padding()
						.background(Color.gray.opacity(0.2))
						.cornerRadius(12)

						// Icon Source Picker
						VStack(spacing: 12) {
							Text("Icon Source")
								.font(.headline)
								.foregroundColor(.white)
							Picker("Icon Source", selection: $iconFetchSource) {
								Text(IconFetchSourceOption.itunes.label).tag(IconFetchSourceOption.itunes)
								Text(IconFetchSourceOption.iconfinder.label).tag(IconFetchSourceOption.iconfinder)
							}
							.pickerStyle(.segmented)
						}
						.padding()
						.background(Color.gray.opacity(0.2))
						.cornerRadius(12)

						// Apply Button
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            applyColorToWidgets()
                            refreshAllWidgets()
                            withTransaction(Transaction(animation: nil)) {
                                didJustApplyWidgets = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                withTransaction(Transaction(animation: nil)) {
                                    didJustApplyWidgets = false
                                }
                            }
                        }) {
                            HStack(alignment: .center, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                Text(didJustApplyWidgets ? "Applied ✅" : "Apply to Widgets")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Widget Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            loadSettings()
        }
    }
    
    // Helper methods for RGB/Hex conversion
    private func sanitizeHexInput(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("#") {
            return String(trimmed.dropFirst())
        }
        return trimmed
    }
    private func updateHexFromRGB() {
        let hex = String(format: "%02X%02X%02X", Int(redComponent), Int(greenComponent), Int(blueComponent))
        backgroundColor = "#" + hex
        customHexInput = hex
    }
    private func updateRGBFromHex() {
        let hex = sanitizeHexInput(backgroundColor)
        if let color = UIColor(hex: "#" + hex) {
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            redComponent = Double(red * 255)
            greenComponent = Double(green * 255)
            blueComponent = Double(blue * 255)
        }
    }
    private func isValidHex(_ hex: String) -> Bool {
        let hexPattern = "^[0-9A-Fa-f]{6}$"
        return hex.range(of: hexPattern, options: .regularExpression) != nil
    }
    
    // Apply color settings to widgets
    private func applyColorToWidgets() {
        let userDefaults = UserDefaults(suiteName: appGroupID)
        userDefaults?.set(backgroundColor, forKey: "WidgetBackgroundColor")
		userDefaults?.set(selectedAlignment.rawValue, forKey: "WidgetTextAlignment")
		userDefaults?.set(iconsEnabled, forKey: "WidgetIconsEnabled")
        userDefaults?.set(iconFetchSource.rawValue, forKey: "IconFetchSource")
        userDefaults?.synchronize()
    }
    
    // Load existing settings
    private func loadSettings() {
        let userDefaults = UserDefaults(suiteName: appGroupID)
        let savedBackgroundColor = userDefaults?.string(forKey: "WidgetBackgroundColor") ?? "#242424"
        let sanitized = sanitizeHexInput(savedBackgroundColor)
        backgroundColor = "#" + sanitized
        customHexInput = sanitized
		if let alignmentRaw = userDefaults?.string(forKey: "WidgetTextAlignment"),
		   let option = TextAlignmentOption(rawValue: alignmentRaw) {
			selectedAlignment = option
		} else {
			selectedAlignment = .leading
		}
		iconsEnabled = userDefaults?.bool(forKey: "WidgetIconsEnabled") ?? true
        if let sourceRaw = userDefaults?.string(forKey: "IconFetchSource"),
           let source = IconFetchSourceOption(rawValue: sourceRaw) {
            iconFetchSource = source
        } else {
            iconFetchSource = .itunes
        }
        updateRGBFromHex()
    }
}

// MARK: - Widget Launchers Configuration View
struct WidgetLaunchersConfigView: View {
    @ObservedObject var store: AppLauncherStore
    @FocusState private var focusedField: Int?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.editMode) private var editMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(0..<5, id: \.self) { widgetIndex in
                    Section(header: Text("WIDGET #\(widgetIndex + 1)").font(.title2).fontWeight(.bold)) {
                        let start = widgetIndex * 8
                        let end = start + 8
                        let upperBound = min(end, store.launchers.count)
                        if start < upperBound {
                            ForEach(store.launchers[start..<upperBound]) { launcher in
                                let slotNumber = launcher.id - start
                                LauncherSlotView(launcher: binding(for: launcher), slotNumber: slotNumber)
                            }
                            .onMove { indices, newOffset in
                                reorderSlots(in: widgetIndex, indices: indices, newOffset: newOffset)
                            }
                        } else {
                            Text("Slots missing. Use Settings → Clear and Reset All Widgets.")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Widgets")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button("Fetch Icons") {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            bulkFetchIcons()
                        }
                        Button("Save") {
                        store.save()
                        dismiss()
                        }
                    }
                }
            }
        }
    }
    
    // Helper to bind to a launcher object
    private func binding(for launcher: AppLauncher) -> Binding<AppLauncher> {
        guard let idx = store.launchers.firstIndex(where: { $0.id == launcher.id }) else {
            print("Launcher not found: id=\(launcher.id)")
            return .constant(launcher)
        }
        return $store.launchers[idx]
    }

    private func reorderSlots(in widgetIndex: Int, indices: IndexSet, newOffset: Int) {
        let start = widgetIndex * 8
        let end = min(start + 8, store.launchers.count)
        guard start < end else { return }
        var slice = Array(store.launchers[start..<end])
        slice.move(fromOffsets: indices, toOffset: newOffset)
        for (i, item) in slice.enumerated() {
            if start + i < store.launchers.count {
                store.launchers[start + i] = item
            }
        }
    }

    private func bulkFetchIcons() {
        let group = DispatchGroup()
        let userDefaults = UserDefaults(suiteName: appGroupID)
        let sourceRaw = userDefaults?.string(forKey: "IconFetchSource") ?? IconFetchSourceOption.itunes.rawValue
        let source = IconFetchSourceOption(rawValue: sourceRaw) ?? .itunes
        for launcherIndex in store.launchers.indices {
            let name = store.launchers[launcherIndex].name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }
            group.enter()
            let completion: (Result<Data, Error>) -> Void = { result in
                DispatchQueue.main.async {
                    if case .success(let data) = result {
                        if let fileName = saveIconDataToAppGroup(data: data, slotId: store.launchers[launcherIndex].id) {
                            store.launchers[launcherIndex].iconFileName = fileName
                            store.launchers[launcherIndex].showIcon = true
                        }
                    }
                    group.leave()
                }
            }
            switch source {
            case .itunes:
                fetchIconForAppName(appName: name, completion: completion)
            case .iconfinder:
                fetchIconFromIconfinder(query: name, completion: completion)
            }
        }
        group.notify(queue: .main) {
            store.save()
            WidgetCenter.shared.reloadAllTimelines()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - Launcher Slot View
struct LauncherSlotView: View {
    @Binding var launcher: AppLauncher
    let slotNumber: Int
    @Environment(\.editMode) private var editMode
    @State private var confirmClear = false
    @State private var testLaunchError: String? = nil
    // Removed per-slot icon UI to reduce clutter

    var body: some View {
		HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("App Slot #\(slotNumber)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                TextField("App Name", text: $launcher.name)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                TextField("URL Scheme", text: $launcher.urlScheme)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
				HStack(spacing: 16) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        let trimmed = launcher.urlScheme.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty, trimmed.contains("://"), let url = URL(string: trimmed) else {
                            testLaunchError = "Invalid URL. Include a scheme, e.g. myapp://"
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                            return
                        }
                        testLaunchError = nil
                        HapticsHelper.handleURLLaunch()
                        UIApplication.shared.open(url) { success in
                            if !success {
                                testLaunchError = "Failed to open. Check the scheme or LSApplicationQueriesSchemes."
                                UINotificationFeedbackGenerator().notificationOccurred(.error)
                            }
                        }
                    }) {
                        Text("Test Launch")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(launcher.urlScheme.isEmpty)
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Test Launch")
                    .accessibilityHint("Open the URL scheme to test it")

                    Button(action: {
                        if confirmClear {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            launcher.name = ""
                            launcher.urlScheme = ""
							launcher.iconFileName = nil
							launcher.showIcon = false
                            confirmClear = false
                        } else {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            confirmClear = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                confirmClear = false
                            }
                        }
                    }) {
                        Text(confirmClear ? "Are you sure?" : "Clear")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(confirmClear ? Color.red : Color.gray)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Clear slot")
                    .accessibilityHint("Clear the name and URL scheme for this slot")
                }

                if let testLaunchError = testLaunchError {
                    Text(testLaunchError)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 4)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("AlwaysShowSettingsButton", store: UserDefaults(suiteName: appGroupID)) private var alwaysShowSettingsButton: Bool = false
    // Import/Export functionality
    @State private var showingImportAlert = false
    @State private var showingExportAlert = false
    @State private var showingDocumentPicker = false
    @State private var showingShareSheet = false
    @State private var exportedData = ""
    @State private var importError = ""
    @State private var exportSuccess = false
    @State private var importSuccess = false
    @State private var shareItems: [Any] = []
    @State private var importFeedbackMessage: String = ""
    // Confirmation state for clear and reset button
    @State private var confirmClearAndReset = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("SETTINGS ACCESS").font(.headline)) {
                    Toggle("Always Show Settings Button", isOn: $alwaysShowSettingsButton)
                }
                
                Section(header: Text("BACKUP & RESTORE").font(.headline)) {
                    Button(action: exportConfiguration) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export App Slots")
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Button(action: importConfiguration) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import App Slots")
                        }
                        .foregroundColor(.green)
                    }
                    
                    Button(action: {
                        if confirmClearAndReset {
                            clearAndResetAllWidgets()
                            confirmClearAndReset = false
                        } else {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            confirmClearAndReset = true
                            // Auto-reset confirmation after 5 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                confirmClearAndReset = false
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "trash.circle")
                            Text(confirmClearAndReset ? "Confirm Reset?" : "Clear and Reset All Widgets")
                        }
                        .foregroundColor(.red)
                    }
                    
                    Text("Backup and restore your widget app configurations in JSON format")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("ABOUT").font(.headline)) {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("2025.08.22")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        resetToDefaults()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset All Settings")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Export Complete", isPresented: $showingExportAlert) {
            Button("Copy to Clipboard") {
                UIPasteboard.general.string = exportedData
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            Button("Share") {
                shareConfiguration()
            }
            Button("OK") { }
        } message: {
            Text("App slots configuration has been exported successfully.")
        }
        .alert("Result", isPresented: $showingImportAlert) {
            Button("OK") { }
        } message: {
            Text(importFeedbackMessage)
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker { url in
                importFromFile(url: url)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
        }
    }
    
    // Import/Export functions
    private func exportConfiguration() {
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            importFeedbackMessage = "Failed to access app data"
            importSuccess = false
            showingImportAlert = true
            return
        }
        
        guard let data = userDefaults.data(forKey: "AppLaunchers"),
              let launchers = try? JSONDecoder().decode([AppLauncher].self, from: data) else {
            importFeedbackMessage = "No app slots found to export"
            importSuccess = false
            showingImportAlert = true
            return
        }
        
        let exportData: [String: Any] = [
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "appVersion": "1.0.0",
            "launchers": launchers.map { launcher in
                [
                    "id": launcher.id,
                    "name": launcher.name,
                    "urlScheme": launcher.urlScheme
                ]
            }
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            exportedData = String(data: jsonData, encoding: .utf8) ?? ""
            
            if !exportedData.isEmpty {
                showingExportAlert = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else {
                importFeedbackMessage = "Failed to generate export data"
                importSuccess = false
                showingImportAlert = true
            }
        } catch {
            importFeedbackMessage = "Failed to export configuration: \(error.localizedDescription)"
            importSuccess = false
            showingImportAlert = true
        }
    }
    
    private func importConfiguration() {
        showingDocumentPicker = true
    }
    
    private func importFromFile(url: URL) {
        do {
            // Ensure we can access the file
            guard url.startAccessingSecurityScopedResource() else {
                importFeedbackMessage = "Cannot access selected file"
                importSuccess = false
                showingImportAlert = true
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            let data = try Data(contentsOf: url)
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                importFeedbackMessage = "Invalid JSON file format"
                importSuccess = false
                showingImportAlert = true
                return
            }
            
            guard let launchersData = json["launchers"] as? [[String: Any]] else {
                importFeedbackMessage = "Invalid file format - missing launchers data"
                importSuccess = false
                showingImportAlert = true
                return
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: launchersData)
            let launchers = try JSONDecoder().decode([AppLauncher].self, from: jsonData)
            
            // Validate we have exactly 40 launchers
            guard launchers.count == 40 else {
                importFeedbackMessage = "Invalid number of app slots (expected 40, got \(launchers.count))"
                importSuccess = false
                showingImportAlert = true
                return
            }
            
            // Save to UserDefaults
            guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
                importFeedbackMessage = "Failed to access app data storage"
                importSuccess = false
                showingImportAlert = true
                return
            }
            
            let encodedData = try JSONEncoder().encode(launchers)
            userDefaults.set(encodedData, forKey: "AppLaunchers")
            
            importSuccess = true
            importFeedbackMessage = "App slots imported successfully!"
            showingImportAlert = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
        } catch {
            importFeedbackMessage = "Failed to import: \(error.localizedDescription)"
            importSuccess = false
            showingImportAlert = true
        }
    }
    
    private func shareConfiguration() {
        guard !exportedData.isEmpty else {
            importFeedbackMessage = "No data to share"
            importSuccess = false
            showingImportAlert = true
            return
        }
        
        // Create temporary file for sharing
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("rocket_launcher_config_\(Date().timeIntervalSince1970).json")
        
        do {
            try exportedData.write(to: tempURL, atomically: true, encoding: .utf8)
            shareItems = [tempURL]
            showingShareSheet = true
        } catch {
            importFeedbackMessage = "Failed to create file for sharing: \(error.localizedDescription)"
            importSuccess = false
            showingImportAlert = true
        }
    }
    
    private func clearAndResetAllWidgets() {
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            importFeedbackMessage = "Failed to access app data"
            importSuccess = false
            showingImportAlert = true
            return
        }
        
        // Create 40 empty launchers (5 widgets × 8 slots each)
        let emptyLaunchers = (0..<40).map { AppLauncher(id: $0) }
        
        do {
            let encodedData = try JSONEncoder().encode(emptyLaunchers)
            userDefaults.set(encodedData, forKey: "AppLaunchers")
            
            // Also refresh all widgets to reflect the changes
            WidgetCenter.shared.reloadAllTimelines()
            
            importFeedbackMessage = "All widgets have been cleared and reset successfully!"
            importSuccess = true
            showingImportAlert = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
        } catch {
            importFeedbackMessage = "Failed to clear widgets: \(error.localizedDescription)"
            importSuccess = false
            showingImportAlert = true
        }
    }
    
    private func resetToDefaults() {
        alwaysShowSettingsButton = false
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onDocumentPicked(url)
        }
    }
}

// MARK: - Document Picker for PNG images
struct DocumentPickerPNG: UIViewControllerRepresentable {
    let onDocumentPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.png])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerPNG
        
        init(_ parent: DocumentPickerPNG) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onDocumentPicked(url)
        }
    }
}

// MARK: - Icon storage helpers
private func iconsDirectoryURL() -> URL? {
    guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else { return nil }
    let dir = container.appendingPathComponent("icons", isDirectory: true)
    if !FileManager.default.fileExists(atPath: dir.path) {
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    return dir
}

private func saveIconToAppGroup(url: URL, slotId: Int) -> String? {
    guard url.startAccessingSecurityScopedResource() else { return nil }
    defer { url.stopAccessingSecurityScopedResource() }
    guard let dir = iconsDirectoryURL() else { return nil }
    let ext = url.pathExtension.lowercased() == "png" ? "png" : (url.pathExtension.isEmpty ? "png" : url.pathExtension)
    let fileName = "slot_\(slotId).\(ext)"
    let destination = dir.appendingPathComponent(fileName)
    do {
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: url, to: destination)
        return fileName
    } catch {
        return nil
    }
}

private func loadIconPreview(for launcher: AppLauncher) -> UIImage? {
    guard let fileName = launcher.iconFileName, let dir = iconsDirectoryURL() else { return nil }
    let url = dir.appendingPathComponent(fileName)
    return UIImage(contentsOfFile: url.path)
}

// MARK: - Auto-fetch icons via iTunes Search API
private func fetchIconForAppName(appName: String, completion: @escaping (Result<Data, Error>) -> Void) {
    // Query iTunes Search API for the app name (US store, software entity)
    let term = appName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? appName
    guard let url = URL(string: "https://itunes.apple.com/search?term=\(term)&country=us&entity=software&limit=1") else {
        completion(.failure(NSError(domain: "itms", code: -1)))
        return
    }
    let task = URLSession.shared.dataTask(with: url) { data, _, error in
        if let error = error {
            completion(.failure(error)); return
        }
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let results = json["results"] as? [[String: Any]],
              let first = results.first else {
            completion(.failure(NSError(domain: "itms", code: -2))); return
        }
        // Prefer high-res artworkUrl512, fallback to 100
        let urlString = (first["artworkUrl512"] as? String) ?? (first["artworkUrl100"] as? String)
        guard let art = urlString, let u = URL(string: art) else {
            completion(.failure(NSError(domain: "itms", code: -3))); return
        }
        // Ensure PNG extension if possible (many are JPG). We'll still accept JPG and save as PNG if convertible.
        URLSession.shared.dataTask(with: u) { imgData, _, err in
            if let err = err { completion(.failure(err)); return }
            guard let imgData = imgData else { completion(.failure(NSError(domain: "itms", code: -4))); return }
            // Try to convert to PNG to ensure transparency compatibility if available
            if let image = UIImage(data: imgData), let pngData = image.pngData() {
                completion(.success(pngData))
            } else {
                completion(.success(imgData))
            }
        }.resume()
    }
    task.resume()
}

private func saveIconDataToAppGroup(data: Data, slotId: Int) -> String? {
    guard let dir = iconsDirectoryURL() else { return nil }
    let fileName = "slot_\(slotId).png"
    let destination = dir.appendingPathComponent(fileName)
    do {
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try data.write(to: destination)
        return fileName
    } catch {
        return nil
    }
}

// MARK: - Iconfinder API fetch
private func fetchIconFromIconfinder(query: String, completion: @escaping (Result<Data, Error>) -> Void) {
    let apiKey = "MXBBMz73Zl5XJrgGWjFe4YASi8rtkzIV0LQSYvPiunpeNWm6wmvG3ydyqHyplDrC"
    guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
          let url = URL(string: "https://api.iconfinder.com/v4/icons/search?query=\(encoded)&count=1&premium=false") else {
        completion(.failure(NSError(domain: "iconfinder", code: -1)))
        return
    }
    var request = URLRequest(url: url)
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    URLSession.shared.dataTask(with: request) { data, _, error in
        if let error = error { completion(.failure(error)); return }
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let icons = json["icons"] as? [[String: Any]],
              let first = icons.first,
              let rasterSizes = first["raster_sizes"] as? [[String: Any]] else {
            completion(.failure(NSError(domain: "iconfinder", code: -2)))
            return
        }
        // Choose the largest PNG download_url
        let sorted = rasterSizes.sorted { (a, b) -> Bool in
            let sa = (a["size"] as? Int) ?? 0
            let sb = (b["size"] as? Int) ?? 0
            return sa > sb
        }
        for sizeEntry in sorted {
            if let formats = sizeEntry["formats"] as? [[String: Any]] {
                if let png = formats.first(where: { ($0["format"] as? String)?.lowercased() == "png" }),
                   let urlStr = png["download_url"] as? String,
                   let dlURL = URL(string: urlStr) {
                    URLSession.shared.dataTask(with: dlURL) { imgData, _, err in
                        if let err = err { completion(.failure(err)); return }
                        guard let imgData = imgData else { completion(.failure(NSError(domain: "iconfinder", code: -3))); return }
                        // ensure PNG output
                        if let image = UIImage(data: imgData), let pngData = image.pngData() {
                            completion(.success(pngData))
                        } else {
                            completion(.success(imgData))
                        }
                    }.resume()
                    return
                }
            }
        }
        completion(.failure(NSError(domain: "iconfinder", code: -4)))
    }.resume()
}

// MARK: - Config Card View
struct ConfigCardView: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
#Preview {
    ContentView()
}
