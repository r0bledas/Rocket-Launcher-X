//
//  ContentView.swift
//  Rocket Launcher
//
//  Created by Raudel Alejandro on 19-07-2025.
// hello

import SwiftUI
import WidgetKit
import UIKit
import UniformTypeIdentifiers
import PhotosUI
import Network


// Centralized App Group ID used across iOS app, widgets, and watch extensions.
let appGroupID = "group.rocketlauncher"

//

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

//

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
    
    /// Sets a slot's contents and kicks off an icon fetch for the given app name.
    func setLauncher(id: Int, name: String, scheme: String) {
        guard let idx = launchers.firstIndex(where: { $0.id == id }) else { return }
        launchers[idx].name = name
        launchers[idx].urlScheme = scheme
        // Clear any previous icon immediately so a stale image can never be shown
        // while the new one is being fetched (or if the fetch fails).
        launchers[idx].iconFileName = nil
        launchers[idx].showIcon = false
        save()
        
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // Only look up catalog names (never free-typed custom names) and only if
        // the user allows Apple icon lookups.
        guard AppIconFetch.shouldFetch(name: trimmed) else { return }
        fetchIconForAppName(appName: trimmed) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self, case .success(let data) = result else { return }
                if let fileName = saveIconDataToAppGroup(data: data, slotId: id) {
                    if let i = self.launchers.firstIndex(where: { $0.id == id }) {
                        self.launchers[i].iconFileName = fileName
                        self.launchers[i].showIcon = true
                    }
                    self.save()
                }
            }
        }
    }
    
    func clearLauncher(id: Int) {
        guard let idx = launchers.firstIndex(where: { $0.id == id }) else { return }
        launchers[idx].name = ""
        launchers[idx].urlScheme = ""
        launchers[idx].iconFileName = nil
        launchers[idx].showIcon = false
        save()
    }

    /// Moves an app into another widget: to its first empty slot, or swaps with
    /// the widget's first slot if it's full. Returns false if the move is invalid.
    @discardableResult
    func moveLauncher(id: Int, toWidgetIndex: Int) -> Bool {
        guard let from = launchers.firstIndex(where: { $0.id == id }) else { return false }
        let start = toWidgetIndex * 8
        let end = min(start + 8, launchers.count)
        guard start < end, !(start..<end).contains(from) else { return false }
        let target = (start..<end).first {
            launchers[$0].name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } ?? start
        guard target != from else { return false }
        launchers.swapAt(from, target)
        save()
        return true
    }

    /// Moves (or swaps) an app into a specific slot, which may be in any widget.
    @discardableResult
    func moveLauncher(id: Int, toSlotID: Int) -> Bool {
        guard let from = launchers.firstIndex(where: { $0.id == id }),
              let to = launchers.firstIndex(where: { $0.id == toSlotID }),
              from != to else { return false }
        launchers.swapAt(from, to)
        save()
        return true
    }
    
    func bulkFetchIcons(completion: (() -> Void)? = nil) {
        let group = DispatchGroup()
        // Always use Apple (iTunes) as icon source
        for launcherIndex in launchers.indices {
            let name = launchers[launcherIndex].name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }
            // Only catalog names, and only when Apple lookups are enabled.
            guard AppIconFetch.shouldFetch(name: name) else { continue }
            group.enter()
            let completion: (Result<Data, Error>) -> Void = { result in
                DispatchQueue.main.async {
                    if case .success(let data) = result {
                        if let fileName = saveIconDataToAppGroup(data: data, slotId: self.launchers[launcherIndex].id) {
                            self.launchers[launcherIndex].iconFileName = fileName
                            self.launchers[launcherIndex].showIcon = true
                        }
                    }
                    group.leave()
                }
            }
            fetchIconForAppName(appName: name, completion: completion)
        }
        group.notify(queue: .main) {
            self.save()
            WidgetCenter.shared.reloadAllTimelines()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            completion?()
        }
    }
}

// MARK: - Haptics Helper

/// Centralized haptics engine.
///
/// Generators are created once and retained, then re-`prepare()`d after each
/// feedback so the Taptic Engine is always warmed up and the next feedback has
/// minimal latency. All feedback is delivered on the main thread, which is
/// required for `UIFeedbackGenerator` to fire.
final class HapticsHelper {
    static let shared = HapticsHelper()

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        prepareGenerators()
    }

    /// Warms up the Taptic Engine. Call when the app becomes active.
    static func prepare() {
        onMain { shared.prepareGenerators() }
    }

    private func prepareGenerators() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        softGenerator.prepare()
        rigidGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }

    static func playLaunchHaptic() { impact(.heavy) }

    // Added this method from the duplicate URLHandler structure
    static func handleURLLaunch() { impact(.heavy) }

    /// Generic impact feedback.
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1.0) {
        onMain {
            let generator = shared.generator(for: style)
            generator.impactOccurred(intensity: intensity)
            generator.prepare()
        }
    }

    /// Selection feedback for pickers, segmented controls and chips.
    static func selection() {
        onMain {
            shared.selectionGenerator.selectionChanged()
            shared.selectionGenerator.prepare()
        }
    }

    static func success() { notification(.success) }
    static func warning() { notification(.warning) }
    static func error() { notification(.error) }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        onMain {
            shared.notificationGenerator.notificationOccurred(type)
            shared.notificationGenerator.prepare()
        }
    }

    private func generator(for style: UIImpactFeedbackGenerator.FeedbackStyle) -> UIImpactFeedbackGenerator {
        switch style {
        case .light: return lightGenerator
        case .medium: return mediumGenerator
        case .heavy: return heavyGenerator
        case .soft: return softGenerator
        case .rigid: return rigidGenerator
        @unknown default: return mediumGenerator
        }
    }

    private static func onMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
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
    @State private var didJustRefreshWidgets = false
    @StateObject private var appLauncherStore = AppLauncherStore()
    @EnvironmentObject var storeManager: StoreManager
    @ObservedObject private var ads = AdsManager.shared
    // Splash overlay state
    @State private var showSplash = true
    @State private var showingSettings = false
    // Purchase alert state
    @State private var showingPurchaseAlert = false
    @State private var purchaseAlertMessage = ""
    @State private var showingPaywall = false
    
    var body: some View {
        ZStack {
            // Black background to appear black when launched from widgets
            Color.black
                .ignoresSafeArea(.all, edges: .all)
            
            mainView
                .ignoresSafeArea(.all, edges: .all)
            
            // Splash on cold launch
            if showSplash {
                Color.black.ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showingWidgetSetup) {
            WidgetSetupView()
        }
        .sheet(isPresented: $showingWidgetConfiguration) {
            WidgetConfigurationView(store: appLauncherStore)
        }
        .sheet(isPresented: $showingWidgetLaunchersConfig) {
            WidgetLaunchersConfigView(store: appLauncherStore)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(store: appLauncherStore)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(storeManager)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                LaunchOverlayWindow.shared.show()
            } else {
                // Warm up the haptics engine whenever the app becomes active.
                HapticsHelper.prepare()
                LaunchOverlayWindow.shared.hide(after: 0.5)
            }
        }
        .onAppear {
            AnalyticsManager.shared.logAppOpen()
            AdsManager.shared.start()
            // Only show splash on cold launch
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showSplash = false
            }
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .alert("Purchase Required", isPresented: $showingPurchaseAlert) {
            Button("OK") { }
        } message: {
            Text(purchaseAlertMessage)
        }
    }
    
    // MARK: - Deep Link Handler
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "rocketlauncher" else { return }
        
        if url.host == "purchase" {
            // Trigger the purchase flow
            if let product = storeManager.products.first(where: { $0.id == RocketProducts.proLifetime }) {
                Task {
                    await storeManager.purchase(product)
                }
            } else {
                purchaseAlertMessage = "Could not load products. Please try again."
                showingPurchaseAlert = true
            }
        }
    }
    
    // MARK: - Main View
    private var mainView: some View {
        ZStack {
            VStack(spacing: 20) {
                Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .cornerRadius(13)
                
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
                    
                    // Pro Purchase Button
                    if !storeManager.purchasedProductIDs.contains(RocketProducts.proLifetime) {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showingPaywall = true
                        }) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                Text("Unlock Pro Features")
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(12)
                            .shadow(color: .purple.opacity(0.4), radius: 5, x: 0, y: 2)
                        }
                        .padding(.top, 10)
                    }
                }
                .padding(.horizontal, 40)
            }
            
            // Settings button overlay - positioned at bottom center without affecting other elements
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showingSettings = true
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
                    .accessibilityLabel("Settings")
                    Spacer()
                }
                .padding(.bottom, 80) // Position above page indicators
            }
            
            // Banner ad (top)
            VStack {
                BannerAdView(ads: ads)
                    .frame(width: 320, height: 50)
                    .padding(.top, 50)
                Spacer()
            }
        }
    }
    
    // MARK: - Ping Tester View (removed)
    /* private var consoleView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Ping Header
                HStack {
                    Text("CARRIER DATA TESTER")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Button(action: {
                        if networkMonitor.isOnCellular {
                            pingAllServices()
                        } else {
                            showingWiFiAlert = true
                        }
                    }) {
                        HStack(spacing: 4) {
                            if isPinging {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .green))
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12))
                            }
                            Text(isPinging ? "TESTING..." : "TEST ALL")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(networkMonitor.isOnCellular ? .green : .gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(networkMonitor.isOnCellular ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                        .cornerRadius(4)
                    }
                    .disabled(isPinging || !networkMonitor.isOnCellular)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 16)
                
                // Network Status
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: networkMonitor.isOnCellular ? "antenna.radiowaves.left.and.right" : "wifi")
                            .font(.system(size: 12))
                            .foregroundColor(networkMonitor.isOnCellular ? .green : .orange)
                        
                        Text(networkMonitor.isOnCellular ? "CELLULAR DATA" : "WIFI CONNECTED")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(networkMonitor.isOnCellular ? .green : .orange)
                    }
                    
                    Spacer()
                    
                    if !networkMonitor.isOnCellular {
                        Text("DISABLE WIFI TO TEST")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                
                // Summary View
                if !pingResults.isEmpty {
                    VStack(spacing: 8) {
                        HStack {
                            Text("SUMMARY")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.yellow)
                            Spacer()
                        }
                        
                        HStack(spacing: 16) {
                            // Web Access
                            VStack(spacing: 2) {
                                Text("WEB")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.blue)
                                let webResults = pingResults.filter { $0.testType == .web }
                                let webOnline = webResults.filter { $0.isOnline }.count
                                Text("\(webOnline)/\(webResults.count)")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(webOnline == webResults.count ? .green : .red)
                            }
                            
                            // API Access
                            VStack(spacing: 2) {
                                Text("API")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.orange)
                                let apiResults = pingResults.filter { $0.testType == .api }
                                let apiOnline = apiResults.filter { $0.isOnline }.count
                                Text("\(apiOnline)/\(apiResults.count)")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(apiOnline == apiResults.count ? .green : .red)
                            }
                            
                            // DNS Access
                            VStack(spacing: 2) {
                                Text("DNS")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.purple)
                                let dnsResults = pingResults.filter { $0.testType == .dns }
                                let dnsOnline = dnsResults.filter { $0.isOnline }.count
                                Text("\(dnsOnline)/\(dnsResults.count)")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(dnsOnline == dnsResults.count ? .green : .red)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                
                // Ping Results or WiFi Warning
                if !networkMonitor.isOnCellular {
                    VStack(spacing: 16) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("WiFi Detected")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                        
                        Text("Carrier data testing requires cellular connection")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Text("Disable WiFi in Settings to test carrier restrictions")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 60)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(pingResults) { result in
                            HStack(alignment: .top, spacing: 8) {
                                // Timestamp
                                Text(timeFormatter.string(from: result.timestamp))
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(.green.opacity(0.7))
                                    .frame(width: 50, alignment: .leading)
                                
                                // Service Name
                                Text(result.service)
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.green)
                                    .frame(width: 60, alignment: .leading)
                                
                                // Test Type
                                Text(result.testType.rawValue)
                                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                                    .foregroundColor(.blue)
                                    .frame(width: 35, alignment: .leading)
                                
                                // Status
                                HStack(spacing: 3) {
                                    Circle()
                                        .fill(result.isOnline ? .green : .red)
                                        .frame(width: 6, height: 6)
                                    
                                    Text(result.isOnline ? "OK" : "FAIL")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundColor(result.isOnline ? .green : .red)
                                }
                                .frame(width: 40, alignment: .leading)
                                
                                // Response Time or Error
                                if result.isOnline, let responseTime = result.responseTime {
                                    Text("\(String(format: "%.0f", responseTime * 1000))ms")
                                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                                        .foregroundColor(.green.opacity(0.8))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } else if let error = result.error {
                                    Text(error)
                                        .font(.system(size: 7, weight: .medium, design: .monospaced))
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(2)
                                } else {
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(result.isOnline ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                            )
                        }
                    }
                    .padding(.bottom, 20)
                }
                }
                
                // Navigation Hint
                VStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Text("Rocket Launcher")
                            .font(.system(size: 9, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 7))
                    }
                    .foregroundColor(.secondary)
                    .padding(.bottom, 12)
                }
            }
        }
        .onAppear {
            // Auto-ping on appear only if on cellular
            if networkMonitor.isOnCellular {
                pingAllServices()
            }
        }
        .alert("WiFi Detected", isPresented: $showingWiFiAlert) {
            Button("OK") { }
        } message: {
            Text("Carrier data testing only works on cellular data. Please disable WiFi to test carrier restrictions.")
        }
    } */
    
    // MARK: - Ping Testing Functions
    
    /* private func pingAllServices() {
        guard !isPinging else { return }
        guard networkMonitor.isOnCellular else {
            showingWiFiAlert = true
            return
        }
        
        isPinging = true
        pingResults.removeAll()
        
        let services = PingResult.Service.allCases
        var totalTests = 0
        var completedTests = 0
        
        // Calculate total tests: web + all API endpoints + dns per service
        for service in services {
            totalTests += 1 // Web test
            totalTests += service.apiEndpoints.count // All API endpoints
            totalTests += 1 // DNS test
        }
        
        for service in services {
            // Test web access
            pingService(service, testType: .web, endpointIndex: 0) { completedTests += 1; checkCompletion() }
            
            // Test all API endpoints for this service
            for (index, endpoint) in service.apiEndpoints.enumerated() {
                pingService(service, testType: .api, endpointIndex: index, customEndpoint: endpoint) { completedTests += 1; checkCompletion() }
            }
            
            // Test DNS resolution
            pingService(service, testType: .dns, endpointIndex: 0) { completedTests += 1; checkCompletion() }
        }
        
        func checkCompletion() {
            if completedTests >= totalTests {
                isPinging = false
            }
        }
    } */
    
    /* private func pingService(_ service: PingResult.Service, testType: PingResult.TestType, endpointIndex: Int, customEndpoint: String? = nil, completion: @escaping () -> Void) {
        let startTime = Date()
        
        // Handle DNS testing separately
        if testType == .dns {
            testDNSResolution(service: service, startTime: startTime, completion: completion)
            return
        }
        
        let urlString: String
        switch testType {
        case .web:
            urlString = service.webURL
        case .api:
            if let customEndpoint = customEndpoint {
                urlString = customEndpoint
            } else {
                // Fallback to legacy single endpoint
                guard let endpoint = service.apiEndpoint else {
                    completion()
                    return
                }
                urlString = endpoint
            }
        case .dns:
            return // Handled above
        }
        
        guard let url = URL(string: urlString) else {
            addPingResult(
                service: service.rawValue,
                testType: testType,
                isOnline: false,
                responseTime: nil,
                error: "Invalid URL",
                statusCode: nil,
                endpointIndex: endpointIndex
            )
            completion()
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"  // Use HEAD for both web and API tests
        request.timeoutInterval = 2.0  // Very short timeout for faster testing
        
        // Add headers for better detection
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let responseTime = Date().timeIntervalSince(startTime)
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode
            
            DispatchQueue.main.async {
                var isOnline = false
                var errorMessage: String? = nil
                
                if let error = error {
                    // Detect specific carrier restrictions
                    if error.localizedDescription.contains("The Internet connection appears to be offline") ||
                       error.localizedDescription.contains("The network connection was lost") ||
                       error.localizedDescription.contains("offline") {
                        errorMessage = "🚫 Carrier Data Limit - Web blocked"
                    } else if error.localizedDescription.contains("timed out") ||
                              error.localizedDescription.contains("timeout") {
                        errorMessage = "⏱️ Timeout - Possible carrier restriction"
                    } else if error.localizedDescription.contains("could not connect") ||
                              error.localizedDescription.contains("connection refused") {
                        errorMessage = "🚫 Connection Refused - Carrier blocking"
                    } else {
                        errorMessage = "❌ \(error.localizedDescription)"
                    }
                } else if let statusCode = statusCode {
                    if statusCode == 200 || statusCode == 204 {
                        isOnline = true
                    } else if statusCode == 403 {
                        errorMessage = "🚫 Forbidden - Carrier may be blocking"
                    } else if statusCode == 429 {
                        errorMessage = "⚠️ Rate Limited - Carrier throttling"
                    } else if statusCode == 404 {
                        errorMessage = "❌ Not Found - Service unavailable"
                    } else {
                        errorMessage = "HTTP \(statusCode)"
                    }
                } else {
                    errorMessage = "❌ No response"
                }
                
                addPingResult(
                    service: service.rawValue,
                    testType: testType,
                    isOnline: isOnline,
                    responseTime: isOnline ? responseTime : nil,
                    error: errorMessage,
                    statusCode: statusCode,
                    endpointIndex: endpointIndex
                )
                
                completion()
            }
        }.resume()
    } */
    
    /* private func testDNSResolution(service: PingResult.Service, startTime: Date, completion: @escaping () -> Void) {
        let host = service.dnsHost
        
        // Use a simple ping-like test to a common port
        let urlString = "http://\(host):80"
        guard let url = URL(string: urlString) else {
            addPingResult(
                service: service.rawValue,
                testType: .dns,
                isOnline: false,
                responseTime: nil,
                error: "🚫 Invalid URL",
                statusCode: nil,
                endpointIndex: 0
            )
            completion()
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 2.0  // Very short timeout for DNS test
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let responseTime = Date().timeIntervalSince(startTime)
            
            DispatchQueue.main.async {
                var isOnline = false
                var errorMessage: String? = nil
                
                if let error = error {
                    if error.localizedDescription.contains("timed out") ||
                       error.localizedDescription.contains("timeout") {
                        errorMessage = "🚫 DNS Timeout - Carrier blocking"
                    } else if error.localizedDescription.contains("could not connect") ||
                              error.localizedDescription.contains("connection refused") {
                        errorMessage = "🚫 DNS Connection Refused - Carrier blocking"
                    } else {
                        errorMessage = "🚫 DNS Error - \(error.localizedDescription)"
                    }
                } else if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    if statusCode == 200 || statusCode == 404 || statusCode == 403 {
                        isOnline = true  // Any response means DNS worked
                    } else {
                        errorMessage = "HTTP \(statusCode)"
                    }
                } else {
                    errorMessage = "🚫 No DNS Response"
                }
                
                addPingResult(
                    service: service.rawValue,
                    testType: .dns,
                    isOnline: isOnline,
                    responseTime: isOnline ? responseTime : nil,
                    error: errorMessage,
                    statusCode: (response as? HTTPURLResponse)?.statusCode,
                    endpointIndex: 0
                )
                
                completion()
            }
        }.resume()
    } */
    
    private func addPingResult() { }
    
    // Removed loadSettings() in favor of @AppStorage
}



// Extension to convert Color to Hex string
extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        if alpha < 1.0 {
            return String(format: "#%02X%02X%02X%02X", 
                          Int(alpha * 255),
                          Int(red * 255), 
                          Int(green * 255), 
                          Int(blue * 255))
        } else {
            return String(format: "#%02X%02X%02X", 
                          Int(red * 255), 
                          Int(green * 255), 
                          Int(blue * 255))
        }
    }
}

// MARK: - Widget Launchers Configuration View
struct WidgetLaunchersConfigView: View {
    @ObservedObject var store: AppLauncherStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("HasPurchasedExtraWidgets", store: UserDefaults(suiteName: appGroupID)) private var hasPurchasedExtraWidgets: Bool = false
    @AppStorage("ShowURLSchemes", store: UserDefaults(suiteName: appGroupID)) private var showURLSchemes = false
    @State private var showPurchaseAlert = false
    @State private var showNoAdAlert = false
    @State private var editingLauncher: AppLauncher? = nil
    @State private var tempUnlockActive = RewardsEntitlement.isActive()
    @State private var movingLauncher: AppLauncher? = nil
    @State private var movingFromWidget: Int = 0
    @ObservedObject private var ads = AdsManager.shared

    var body: some View {
        NavigationView {
            List {
                ForEach(0..<5, id: \.self) { widgetIndex in
                    let isLocked = widgetIndex >= 1 && !hasPurchasedExtraWidgets && !tempUnlockActive
                    Section(header: HStack {
                        Text("WIDGET #\(widgetIndex + 1)")
                            .font(.title2)
                            .fontWeight(.bold)
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.orange)
                        }
                    }) {
                        let start = widgetIndex * 8
                        let end = start + 8
                        let upperBound = min(end, store.launchers.count)
                        if start < upperBound {
                            if isLocked {
                                // Show blurred slots with overlay
                                ZStack {
                                    VStack(spacing: 0) {
                                        ForEach(Array(store.launchers[start..<upperBound].enumerated()), id: \.element.id) { index, launcher in
                                            LauncherSlotView(launcher: launcher, slotNumber: index)
                                                .disabled(true)
                                        }
                                    }
                                    .blur(radius: 8)

                                    VStack(spacing: 16) {
                                        Text("🔒")
                                            .font(.system(size: 80))

                                        Button(action: {
                                            HapticsHelper.impact(.medium)
                                            showPurchaseAlert = true
                                        }) {
                                            Text("Unlock (~$49 MXN)")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 24)
                                                .padding(.vertical, 12)
                                                .background(Color.orange)
                                                .cornerRadius(10)
                                        }

                                        Button(action: {
                                            HapticsHelper.impact(.medium)
                                            AdsManager.shared.presentRewarded {
                                                RewardsEntitlement.grant()
                                                tempUnlockActive = RewardsEntitlement.isActive()
                                                WidgetCenter.shared.reloadAllTimelines()
                                            } onUnavailable: {
                                                showNoAdAlert = true
                                            }
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "play.circle.fill")
                                                Text(ads.isRewardedReady ? "Watch ad to unlock 3 days" : "Loading ad…")
                                            }
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .background(Capsule().fill(Color.blue))
                                        }
                                        .disabled(!ads.isRewardedReady)
                                        .opacity(ads.isRewardedReady ? 1 : 0.5)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                    .background(Color.black.opacity(0.3))
                                }
                            } else {
                                ForEach(Array(store.launchers[start..<upperBound].enumerated()), id: \.element.id) { index, launcher in
                                    Button {
                                        HapticsHelper.impact(.light)
                                        editingLauncher = launcher
                                    } label: {
                                        LauncherSlotView(launcher: launcher, slotNumber: index)
                                    }
                                    .buttonStyle(.plain)
                                    .listRowInsets(EdgeInsets(
                                        top: showURLSchemes ? 6 : 1,
                                        leading: 16,
                                        bottom: showURLSchemes ? 6 : 1,
                                        trailing: 16
                                    ))
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button {
                                            HapticsHelper.impact(.light)
                                            movingLauncher = launcher
                                            movingFromWidget = widgetIndex
                                        } label: {
                                            Label("Move", systemImage: "arrow.left.arrow.right")
                                        }
                                        .tint(.blue)
                                    }
                                }
                                .onMove { indices, newOffset in
                                    reorderSlots(in: widgetIndex, indices: indices, newOffset: newOffset)
                                }
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
                    Button {
                        HapticsHelper.impact(.light)
                        store.save()
                        WidgetCenter.shared.reloadAllTimelines()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Save and close")
                }
            }
            .alert("Purchase Required", isPresented: $showPurchaseAlert) {
                Button("OK") { }
            } message: {
                Text("This is a purchase simulator. In the production app, this would open the App Store purchase flow for the Extra Widgets pack (~$49 MXN).")
            }
            .alert("No ad available", isPresented: $showNoAdAlert) {
                Button("OK") { }
            } message: {
                Text("No ad is available right now. Please try again later.")
            }
            .confirmationDialog(
                "Move to another widget",
                isPresented: Binding(
                    get: { movingLauncher != nil },
                    set: { if !$0 { movingLauncher = nil } }
                ),
                titleVisibility: .visible
            ) {
                ForEach(0..<5, id: \.self) { widgetIndex in
                    if widgetIndex != movingFromWidget,
                       widgetIndex == 0 || hasPurchasedExtraWidgets || tempUnlockActive {
                        Button("Widget #\(widgetIndex + 1)") {
                            if let launcher = movingLauncher,
                               store.moveLauncher(id: launcher.id, toWidgetIndex: widgetIndex) {
                                HapticsHelper.impact(.medium)
                                WidgetCenter.shared.reloadAllTimelines()
                            }
                            movingLauncher = nil
                        }
                    }
                }
                Button("Cancel", role: .cancel) { movingLauncher = nil }
            } message: {
                if let launcher = movingLauncher {
                    Text("Move “\(launcher.name)” into another widget’s first empty slot.")
                }
            }
            .sheet(item: $editingLauncher) { launcher in
                AppPickerView(store: store, launcherID: launcher.id)
            }
        }
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
}

// MARK: - Launcher Slot View
struct LauncherSlotView: View {
    let launcher: AppLauncher
    let slotNumber: Int
    @AppStorage("ShowURLSchemes", store: UserDefaults(suiteName: appGroupID)) private var showURLSchemes = false

    var body: some View {
        HStack(spacing: 12) {
            iconPreview

            VStack(alignment: .leading, spacing: 3) {
                if launcher.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Empty — tap to add an app")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text(launcher.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    if showURLSchemes {
                        Text(launcher.urlScheme)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundColor(.white)
        }
        .padding(.vertical, showURLSchemes ? 6 : 2)
        .contentShape(Rectangle())
    }

    private var iconSize: CGFloat { showURLSchemes ? 44 : 32 }

    private var iconPreview: some View {
        Group {
            if let img = loadIconPreview(for: launcher) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: iconSize * 0.2237, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: iconSize * 0.2237, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: iconSize, height: iconSize)
                    .overlay(
                        Image(systemName: "app.dashed")
                            .font(.system(size: iconSize * 0.4))
                            .foregroundColor(Color.white.opacity(0.4))
                    )
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - App Picker (searchable catalog + advanced manual entry)
/// On-device installed-app check for the picker.
///
/// DISABLED ON PURPOSE. Apple caps `LSApplicationQueriesSchemes` at 50, so we
/// can only detect a subset of the catalog; sorting/badging just that subset
/// while leaving the rest unmarked is misleading. The implementation is kept
/// here (and the scheme list lives in `Info.plist`) so it can be re-enabled by
/// flipping `isEnabled` to `true` once we have a complete, reliable strategy.
@MainActor
final class InstalledAppsStore: ObservableObject {
    static let isEnabled = false

    @Published private(set) var installedSchemes: Set<String> = []
    private var lastRefresh = Date.distantPast

    func refreshIfNeeded(force: Bool = false) {
        guard Self.isEnabled else { return }
        guard force || Date().timeIntervalSince(lastRefresh) > 60 else { return }
        lastRefresh = Date()
        let declared = Bundle.main.object(forInfoDictionaryKey: "LSApplicationQueriesSchemes") as? [String] ?? []
        var found = Set<String>()
        for scheme in declared {
            guard let url = URL(string: "\(scheme)://") else { continue }
            if UIApplication.shared.canOpenURL(url) {
                found.insert(scheme.lowercased())
            }
        }
        installedSchemes = found
    }

    func isInstalled(scheme: String) -> Bool {
        guard Self.isEnabled else { return false }
        guard let colon = scheme.firstIndex(of: ":") else { return false }
        let name = scheme[..<colon].lowercased()
        return installedSchemes.contains(name)
    }
}

struct AppPickerView: View {
    @ObservedObject var store: AppLauncherStore
    let launcherID: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var catalog = AppCatalogStore()
    // Inactive experiment: guarded by InstalledAppsStore.isEnabled.
    @StateObject private var installedApps = InstalledAppsStore()
    @State private var searchText = ""
    @State private var advancedMode = false
    @State private var customName = ""
    @State private var customScheme = ""
    @State private var pendingApp: CatalogApp?
    @State private var duplicateSlotIDs: [Int] = []
    @State private var showDuplicateAlert = false
    @FocusState private var searchFocused: Bool
    @AppStorage("ShowURLSchemes", store: UserDefaults(suiteName: appGroupID)) private var showURLSchemes = false

    private var current: AppLauncher {
        store.launchers.first(where: { $0.id == launcherID }) ?? AppLauncher(id: launcherID)
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var filteredApps: [CatalogApp] {
        installedFirst(AppCatalog.search(searchText, in: catalog.apps))
    }

    /// Curated famous apps (our bundled list) shown as "Suggested" before searching,
    /// ordered by popularity/category rather than alphabetically. Capped to the
    /// top `suggestedLimit`; the rest fall through to "More Apps".
    private var suggestedApps: [CatalogApp] {
        let curated = Set(AppCatalog.bundled.map { $0.name.lowercased() })
        let curatedApps = catalog.apps.filter { curated.contains($0.name.lowercased()) }
        let top = Array(AppCatalog.orderSuggested(curatedApps).prefix(AppCatalog.suggestedLimit))
        return installedFirst(top)
    }

    private var otherApps: [CatalogApp] {
        let suggestedIDs = Set(suggestedApps.map { $0.id })
        let curated = Set(AppCatalog.bundled.map { $0.name.lowercased() })
        let remainingCurated = catalog.apps.filter {
            curated.contains($0.name.lowercased()) && !suggestedIDs.contains($0.id)
        }
        let rest = catalog.apps.filter { !curated.contains($0.name.lowercased()) }
        return installedFirst(AppCatalog.orderSuggested(remainingCurated) + rest)
    }

    /// Puts apps that are installed on this device first, keeping the incoming order.
    /// Disabled while `InstalledAppsStore.isEnabled` is `false`.
    private func installedFirst(_ apps: [CatalogApp]) -> [CatalogApp] {
        guard InstalledAppsStore.isEnabled else { return apps }
        let installed = apps.filter { installedApps.isInstalled(scheme: $0.scheme) }
        let rest = apps.filter { !installedApps.isInstalled(scheme: $0.scheme) }
        return installed + rest
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search apps", text: $searchText)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .focused($searchFocused)
                            .submitLabel(.done)
                            .onSubmit { searchFocused = false }
                        if !searchText.isEmpty {
                            Button {
                                HapticsHelper.impact(.light)
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Clear search")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { searchFocused = true }
                }

                if isSearching {
                    Section {
                        if filteredApps.isEmpty {
                            Text("No apps match “\(searchText)”.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(filteredApps) { app in
                                catalogButton(app)
                            }
                        }
                    } header: {
                        sectionHeader(filteredApps.isEmpty ? "NO RESULTS" : "RESULTS",
                                      count: filteredApps.isEmpty ? nil : filteredApps.count)
                    }

                    Section {
                        Button {
                            HapticsHelper.impact(.light)
                            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                            let term = "\"\(query)\" app url scheme prefix"
                            if let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                               let url = URL(string: "https://www.google.com/search?q=\(encoded)") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "safari")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .frame(width: 40, height: 40)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Look up “\(searchText)” URL scheme")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.white)
                                    Text("Opens Google in Safari")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    } header: {
                        sectionHeader("CAN'T FIND IT?")
                    }
                } else {
                    Section {
                        ForEach(suggestedApps) { app in
                            catalogButton(app)
                        }
                    } header: {
                        sectionHeader("SUGGESTED", count: suggestedApps.count)
                    }

                    Section {
                        ForEach(otherApps) { app in
                            catalogButton(app)
                        }
                    } header: {
                        sectionHeader("MORE APPS", count: otherApps.count)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add App")
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
                    .accessibilityLabel("Cancel")
                }
                if #available(iOS 26.0, *) {
                    // Keep Cancel and Clear as separate glass items (not one merged pill).
                    ToolbarSpacer(.fixed, placement: .navigationBarLeading)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .destructive) {
                        HapticsHelper.impact(.heavy)
                        store.clearLauncher(id: launcherID)
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .tint(.red)
                    .accessibilityLabel("Clear slot")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticsHelper.impact(.light)
                        advancedMode = true
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .accessibilityLabel("Advanced options")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { searchFocused = false }
                }
            }
            .navigationDestination(isPresented: $advancedMode) {
                AdvancedAppForm(name: $customName, scheme: $customScheme) { name, scheme in
                    if name.isEmpty {
                        store.clearLauncher(id: launcherID)
                    } else {
                        store.setLauncher(id: launcherID, name: name, scheme: scheme)
                    }
                    dismiss()
                }
            }
            .onAppear {
                customName = current.name
                customScheme = current.urlScheme
                // No-op while the installed-app experiment is disabled.
                installedApps.refreshIfNeeded()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    installedApps.refreshIfNeeded(force: true)
                }
            }
            .task {
                await catalog.loadRemoteIfNeeded()
            }
            .alert("Already added", isPresented: $showDuplicateAlert, presenting: pendingApp) { app in
                Button("Add Anyway") { commitAdd(app) }
                if duplicateSlotIDs.count == 1, let source = duplicateSlotIDs.first {
                    Button("Move Here") {
                        store.moveLauncher(id: source, toSlotID: launcherID)
                        WidgetCenter.shared.reloadAllTimelines()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {
                    pendingApp = nil
                    duplicateSlotIDs = []
                }
            } message: { app in
                Text(duplicateMessage(for: app))
            }
        }
    }

    /// Adds a catalog app, but first checks every slot (in every widget) for the
    /// same URL scheme. Only an exact scheme match triggers the confirmation.
    private func requestAdd(_ app: CatalogApp) {
        let duplicates = store.launchers.filter {
            $0.id != launcherID &&
            $0.urlScheme.caseInsensitiveCompare(app.scheme) == .orderedSame
        }
        guard !duplicates.isEmpty else {
            commitAdd(app)
            return
        }
        pendingApp = app
        duplicateSlotIDs = duplicates.map { $0.id }
        showDuplicateAlert = true
    }

    private func commitAdd(_ app: CatalogApp) {
        store.setLauncher(id: launcherID, name: app.name, scheme: app.scheme)
        dismiss()
    }

    private func duplicateMessage(for app: CatalogApp) -> String {
        let locations = duplicateSlotIDs.compactMap { id -> String? in
            guard let index = store.launchers.firstIndex(where: { $0.id == id }) else { return nil }
            return "Widget \(index / 8 + 1), slot \(index % 8 + 1)"
        }
        return "“\(app.name)” is already in \(locations.joined(separator: ", ")). Add it again?"
    }

    private func sectionHeader(_ title: String, count: Int? = nil) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)

            Spacer(minLength: 8)

            if let count {
                Text("\(count)")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }
        }
        .padding(.leading, -4)
    }

    @ViewBuilder
    private func catalogButton(_ app: CatalogApp) -> some View {
        Button {
            HapticsHelper.impact(.medium)
            requestAdd(app)
        } label: {
            catalogRow(app)
        }
        .listRowInsets(EdgeInsets(top: showURLSchemes ? 8 : 3,
                                  leading: 16,
                                  bottom: showURLSchemes ? 8 : 3,
                                  trailing: 16))
    }

    private func catalogRow(_ app: CatalogApp) -> some View {
        HStack(spacing: 12) {
            CatalogIconView(name: app.name, size: showURLSchemes ? 40 : 30)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(app.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                    if installedApps.isInstalled(scheme: app.scheme) {
                        // Hidden while InstalledAppsStore.isEnabled is false.
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .accessibilityLabel("Installed")
                    }
                }
                if showURLSchemes {
                    Text(app.scheme)
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
        }
    }
}

// MARK: - Advanced (custom) app form
struct AdvancedAppForm: View {
    @Binding var name: String
    @Binding var scheme: String
    let onSave: (String, String) -> Void

    @State private var previewIcon: UIImage?
    @State private var fetchedKey: String = ""
    @State private var testStatus: String?

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    previewView

                    VStack(alignment: .leading, spacing: 2) {
                        Text(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Custom App" : name)
                            .font(.headline)
                            .foregroundColor(.white)
                        if !scheme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(scheme)
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 2)
            } header: {
                Text("PREVIEW")
            }

            Section {
                TextField("Title", text: $name)
                    .onChange(of: name) { _, _ in refreshPreviewIfNeeded() }
                TextField("URL Scheme", text: $scheme)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: scheme) { _, _ in refreshPreviewIfNeeded() }
            } header: {
                Text("CUSTOM APP")
            } footer: {
                Text("Enter a custom title and URL scheme, e.g. myapp://")
            }

            Section {
                Button {
                    HapticsHelper.impact(.light)
                    refreshPreviewIfNeeded(force: true)
                } label: {
                    Label("Force Fetch Icon", systemImage: "arrow.clockwise")
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !AppIconFetch.isEnabled)
            } header: {
                Text("ICON")
            } footer: {
                if AppIconFetch.isEnabled {
                    Text("Fetches the icon for the title above from Apple.")
                } else {
                    Text("Enable “Fetch app icons from Apple” in Settings first.")
                }
            }

            Section {
                Button {
                    testScheme()
                } label: {
                    Label("Test URL Scheme", systemImage: "play.circle")
                }
                .disabled(scheme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } footer: {
                if let testStatus {
                    Text(testStatus)
                } else {
                    Text("Opens the scheme in the target app. If nothing happens, the app may not be installed or the scheme may be wrong.")
                }
            }
        }
        .navigationTitle("Custom App")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    HapticsHelper.impact(.medium)
                    onSave(name.trimmingCharacters(in: .whitespacesAndNewlines),
                           scheme.trimmingCharacters(in: .whitespacesAndNewlines))
                } label: {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("Save custom app")
            }
        }
    }

    private func testScheme() {
        let trimmed = scheme.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), url.scheme != nil else {
            testStatus = "That doesn’t look like a valid URL scheme. Try something like myapp://"
            return
        }
        HapticsHelper.impact(.medium)
        UIApplication.shared.open(url, options: [:]) { success in
            DispatchQueue.main.async {
                testStatus = success
                    ? "Opened \(trimmed) successfully."
                    : "Could not open \(trimmed). The app may not be installed, or the scheme may be wrong."
            }
        }
    }

    private var previewView: some View {
        Group {
            if let previewIcon {
                Image(uiImage: previewIcon)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        Image(systemName: "app.dashed")
                            .foregroundColor(Color.white.opacity(0.4))
                    )
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityHidden(true)
    }

    /// Fetches a preview icon once a scheme is completed with "://".
    private func refreshPreviewIfNeeded(force: Bool = false) {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedScheme = scheme.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, AppIconFetch.isEnabled else { return }
        guard force || trimmedScheme.hasSuffix("://") else { return }

        let key = "\(title)|\(trimmedScheme)"
        if !force {
            guard key != fetchedKey else { return }
        }
        fetchedKey = key

        fetchIconForAppName(appName: title) { result in
            DispatchQueue.main.async {
                if case .success(let data) = result, let image = UIImage(data: data) {
                    previewIcon = image
                }
            }
        }
    }
}

// MARK: - Settings View
private struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct SettingsView: View {
    @ObservedObject var store: AppLauncherStore
    @ObservedObject private var ads = AdsManager.shared
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ShowURLSchemes", store: UserDefaults(suiteName: appGroupID)) private var showURLSchemes = false
    @State private var wallpaperItem: PhotosPickerItem? = nil
    @State private var wallpaperImage: UIImage? = nil
    @State private var isProcessingWallpaper = false
    @State private var cropImage: IdentifiableImage? = nil
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
    @State private var isRefetchingIcons = false
    @State private var shareAnalytics: Bool = AnalyticsManager.shared.isEnabled
    @State private var analyticsID: String = AnalyticsManager.shared.installID
    @State private var fetchIconsFromApple: Bool = AppIconFetch.isEnabled
    @State private var loadRemoteCatalog: Bool = AppCatalog.remoteFetchEnabled
    // Purchase simulation state
    @AppStorage("HasPurchasedExtraWidgets", store: UserDefaults(suiteName: appGroupID)) private var hasPurchasedExtraWidgets: Bool = false
    @AppStorage("HasPurchasedIconFeature", store: UserDefaults(suiteName: appGroupID)) private var hasPurchasedIconFeature: Bool = false
    @AppStorage("HasPurchasedCalendar", store: UserDefaults(suiteName: appGroupID)) private var hasPurchasedCalendar: Bool = false
    @AppStorage("HasPurchasedTextAlignment", store: UserDefaults(suiteName: appGroupID)) private var hasPurchasedTextAlignment: Bool = false
    // Calendar widget tap settings (local state for immediate UI updates)
    @State private var calendarUseCustomURL: Bool = UserDefaults(suiteName: appGroupID)?.bool(forKey: "CalendarWidgetUseCustomURL") ?? false
    
    // Display zoom detection
    private var displayZoomStatus: String {
        let screen = UIScreen.main
        let scale = screen.scale
        let nativeScale = screen.nativeScale
        
        if scale != nativeScale {
            return "Zoomed (Larger)"
        } else {
            return "Standard"
        }
    }
    
    private var screenSizeInfo: String {
        let bounds = UIScreen.main.bounds
        return String(format: "%.0f×%.0f pt", bounds.width, bounds.height)
    }
    
    private var scaleInfo: String {
        let screen = UIScreen.main
        let scale = screen.scale
        let nativeScale = screen.nativeScale
        return String(format: "%.0f/%.0f", scale, nativeScale)
    }

    /// True when the image already matches this device's screen aspect ratio.
    private func matchesScreenAspect(_ image: UIImage) -> Bool {
        let screen = UIScreen.main.bounds
        guard screen.height > 0, image.size.height > 0 else { return false }
        let screenRatio = screen.width / screen.height
        let imageRatio = image.size.width / image.size.height
        return abs(imageRatio - screenRatio) < 0.02
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("BACKUP & RESTORE").font(.headline)) {
                    Button(action: {
                        HapticsHelper.impact(.light)
                        exportConfiguration()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export App Slots")
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        HapticsHelper.impact(.light)
                        importConfiguration()
                    }) {
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
                
                Section(header: Text("WIDGET CONFIGURATION").font(.headline)) {
                    Button(action: {
                        HapticsHelper.impact(.medium)
                        isRefetchingIcons = true
                        store.bulkFetchIcons {
                            isRefetchingIcons = false
                        }
                    }) {
                        HStack {
                            if isRefetchingIcons {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                            Text(isRefetchingIcons ? "Refetching Icons…" : "Refetch Icons")
                        }
                        .foregroundColor(.blue)
                    }
                    .disabled(isRefetchingIcons)
                    
                    Toggle("Show URL schemes", isOn: $showURLSchemes)
                        .onChange(of: showURLSchemes) { _, _ in
                            HapticsHelper.impact(.light)
                        }
                }
                
                Section(header: Text("LAUNCH BACKGROUND").font(.headline)) {
                    HStack(spacing: 12) {
                        Group {
                            if let image = wallpaperImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Color.black
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.secondary)
                                    )
                            }
                        }
                        .frame(width: 52, height: 92)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            if isProcessingWallpaper {
                                ZStack {
                                    Color.black.opacity(0.55)
                                    ProgressView()
                                        .tint(.white)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Shown while switching apps")
                                .font(.subheadline.weight(.semibold))
                            Text("Pick an image similar to your Home Screen wallpaper so the launch/return transition blends in. Stored on this device only.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)

                    PhotosPicker(selection: $wallpaperItem, matching: .images) {
                        Label(wallpaperImage == nil ? "Choose Image" : "Change Image", systemImage: "photo.on.rectangle")
                    }
                    .disabled(isProcessingWallpaper)

                    if wallpaperImage != nil {
                        Button(role: .destructive) {
                            HapticsHelper.impact(.light)
                            LaunchOverlayModel.shared.clear()
                            wallpaperImage = nil
                            wallpaperItem = nil
                        } label: {
                            Label("Remove Wallpaper", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
                .onChange(of: wallpaperItem) { _, newItem in
                    guard let newItem else { return }
                    isProcessingWallpaper = true
                    Task {
                        let data = try? await newItem.loadTransferable(type: Data.self)
                        await MainActor.run {
                            isProcessingWallpaper = false
                            guard let data, let image = UIImage(data: data) else { return }
                            if matchesScreenAspect(image) {
                                LaunchOverlayModel.shared.setImage(image)
                                wallpaperImage = LaunchOverlayModel.shared.image
                                HapticsHelper.impact(.medium)
                            } else {
                                cropImage = IdentifiableImage(image: image)
                            }
                        }
                    }
                }
                .fullScreenCover(item: $cropImage) { item in
                    WallpaperCropView(
                        image: item.image,
                        onCancel: { cropImage = nil },
                        onUse: { cropped in
                            LaunchOverlayModel.shared.setImage(cropped)
                            wallpaperImage = LaunchOverlayModel.shared.image
                            HapticsHelper.impact(.medium)
                            cropImage = nil
                        }
                    )
                }
                
                Section(header: Text("PRIVACY").font(.headline)) {
                    Toggle("Share anonymous usage data", isOn: $shareAnalytics)
                        .onChange(of: shareAnalytics) { _, newValue in
                            AnalyticsManager.shared.isEnabled = newValue
                            HapticsHelper.impact(.light)
                        }
                    Text("On by default. Turn off to stop sending pseudonymous app-launch statistics: app name, full URL scheme (including custom schemes you type), widget number and slot, local hour of day, and basic device context under a random install ID. No name, email, contacts, or content is collected.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Toggle("Fetch app icons from Apple", isOn: $fetchIconsFromApple)
                        .onChange(of: fetchIconsFromApple) { _, newValue in
                            UserDefaults(suiteName: appGroupID)?.set(newValue, forKey: "FetchAppIconsFromApple")
                            HapticsHelper.impact(.light)
                        }
                    Toggle("Load community app catalog", isOn: $loadRemoteCatalog)
                        .onChange(of: loadRemoteCatalog) { _, newValue in
                            UserDefaults(suiteName: appGroupID)?.set(newValue, forKey: "RemoteAppCatalogEnabled")
                            HapticsHelper.impact(.light)
                        }
                    Text("Icon lookup sends app names (including custom titles you enter) to Apple's iTunes Search API to fetch icons. Turn this off to keep the app fully offline (bundled list + placeholder icons).")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Analytics ID")
                                .font(.subheadline)
                            Text(analyticsID)
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        Button {
                            HapticsHelper.impact(.light)
                            UIPasteboard.general.string = analyticsID
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Copy analytics ID")
                    }
                    Button {
                        HapticsHelper.impact(.medium)
                        AnalyticsManager.shared.resetInstallID()
                        analyticsID = AnalyticsManager.shared.installID
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset analytics ID")
                        }
                        .foregroundColor(.blue)
                    }
                    Text("This random ID is a persistent identifier stored on this device only; it is never restored from backups. Copy it and email \("raudel@raudel.lat") to request access to or deletion of your analytics data.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if ads.privacyOptionsRequired {
                        Button {
                            HapticsHelper.impact(.light)
                            AdsManager.shared.presentPrivacyOptions()
                        } label: {
                            HStack {
                                Image(systemName: "hand.raised.fill")
                                Text("Privacy options")
                            }
                            .foregroundColor(.blue)
                        }
                    }

                    #if DEBUG
                    Button {
                        HapticsHelper.impact(.light)
                        AdsManager.shared.resetConsent()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset ad consent (debug)")
                        }
                        .foregroundColor(.orange)
                    }
                    #endif
                }
                
                Section(header: Text("CALENDAR WIDGET").font(.headline)) {
                    Toggle("Enable Tap to Open", isOn: Binding(
                        get: {
                            let userDefaults = UserDefaults(suiteName: appGroupID)
                            return userDefaults?.bool(forKey: "CalendarWidgetTapEnabled") ?? false
                        },
                        set: { newValue in
                            let userDefaults = UserDefaults(suiteName: appGroupID)
                            userDefaults?.set(newValue, forKey: "CalendarWidgetTapEnabled")
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                    ))
                    
                    Picker("Tap Action", selection: $calendarUseCustomURL) {
                        Text("Open Calendar App").tag(false)
                        Text("Custom URL Scheme").tag(true)
                    }
                    .pickerStyle(.menu)
                    .onChange(of: calendarUseCustomURL) { _, newValue in
                        let userDefaults = UserDefaults(suiteName: appGroupID)
                        userDefaults?.set(newValue, forKey: "CalendarWidgetUseCustomURL")
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                    
                    if calendarUseCustomURL {
                        TextField("Custom URL Scheme", text: Binding(
                            get: {
                                let userDefaults = UserDefaults(suiteName: appGroupID)
                                return userDefaults?.string(forKey: "CalendarWidgetCustomURL") ?? ""
                            },
                            set: { newValue in
                                let userDefaults = UserDefaults(suiteName: appGroupID)
                                userDefaults?.set(newValue, forKey: "CalendarWidgetCustomURL")
                            }
                        ))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .onSubmit {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                        
                        Text("Example: fantastical2:// or google-calendar://")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("When enabled, tapping the calendar widget will open the selected app")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                #if DEBUG
                Section(header: Text("DEV BETA").font(.headline)) {
                    Toggle("Calendar Edge Day Testing", isOn: Binding(
                        get: {
                            let userDefaults = UserDefaults(suiteName: appGroupID)
                            return userDefaults?.bool(forKey: "CalendarEdgeDayTesting") ?? false
                        },
                        set: { newValue in
                            let userDefaults = UserDefaults(suiteName: appGroupID)
                            userDefaults?.set(newValue, forKey: "CalendarEdgeDayTesting")
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            // Refresh widgets to apply change
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                    ))
                    
                    Text("Always show the active day circle at left edge (Sundays) or right edge (Saturdays) for testing widget layout at column edges")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Purchase Simulator
                    Text("PURCHASE SIMULATOR")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .padding(.top, 8)
                    
                    Toggle("Owns \"Extra Widgets\"", isOn: $hasPurchasedExtraWidgets)
                        .onChange(of: hasPurchasedExtraWidgets) { _, _ in
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        .listRowSeparator(.hidden)
                    

                    
                    Toggle("Owns \"Icon Feature\"", isOn: $hasPurchasedIconFeature)
                        .onChange(of: hasPurchasedIconFeature) { _, _ in
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        .listRowSeparator(.hidden)
                    

                    
                    Toggle("Owns \"Calendar Widget\"", isOn: $hasPurchasedCalendar)
                        .onChange(of: hasPurchasedCalendar) { _, _ in
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                        .listRowSeparator(.hidden)
                    

                    
                    Toggle("Owns \"Text Alignment\"", isOn: $hasPurchasedTextAlignment)
                        .onChange(of: hasPurchasedTextAlignment) { _, _ in
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                        .listRowSeparator(.hidden)
                    

                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        hasPurchasedExtraWidgets = false
                        hasPurchasedIconFeature = false
                        hasPurchasedCalendar = false
                        hasPurchasedTextAlignment = false
                        storeManager.resetStatus()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset All Purchases (StoreKit & Local)")
                        }
                        .foregroundColor(.red)
                    }
                    
                    // Display Zoom Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("iOS Display Zoom")
                            Spacer()
                            Text(displayZoomStatus)
                                .foregroundColor(.secondary)
                        }
                        Text("Screen: \(screenSizeInfo) • Scale: \(scaleInfo)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                #endif
                
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
                
                Section(header: Text("LEGAL").font(.headline)) {
                    // Privacy Policy Link
                    Button(action: {
                        HapticsHelper.impact(.light)
                        // TODO: Replace with your actual Privacy Policy URL before App Store submission
                        if let url = URL(string: "https://r0bledas.github.io/Rocket-Launcher-X/privacy.html") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.blue)
                            Text("Privacy Policy")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Terms of Service Link
                    Button(action: {
                        HapticsHelper.impact(.light)
                        // TODO: Replace with your actual Terms of Service URL before App Store submission
                        if let url = URL(string: "https://r0bledas.github.io/Rocket-Launcher-X/terms.html") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.blue)
                            Text("Terms of Service")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { wallpaperImage = LaunchOverlayModel.shared.image }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticsHelper.impact(.light)
                        WidgetCenter.shared.reloadAllTimelines()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Done")
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
            
            // Reload store and widgets
            store.load()
            WidgetCenter.shared.reloadAllTimelines()
            
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
            
            // Reload store
            store.load()
            
        } catch {
            importFeedbackMessage = "Failed to clear widgets: \(error.localizedDescription)"
            importSuccess = false
            showingImportAlert = true
        }
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
func iconsDirectoryURL() -> URL? {
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

func loadIconPreview(for launcher: AppLauncher) -> UIImage? {
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
