//
//  Analytics.swift
//  Rocket Launcher
//
//  Privacy-first, pseudonymous usage analytics.
//
//  Design goals:
//   - OPT-IN: disabled by default. Nothing is sent until the user turns on
//     Settings → Privacy → "Share anonymous usage data".
//   - App-launch events include the app name and the full URL scheme (including
//     custom schemes), the widget number and slot, and the local hour of day.
//     This is what lets us see which apps are tapped most and when. It is only
//     ever sent with explicit opt-in consent.
//   - Pseudonymous: a random install id stored in the Keychain
//     (this-device-only). It is a persistent identifier, resettable in Settings.
//     No IDFA, names, emails, precise location, or content.
//   - Self-hosted: posts to an Umami-compatible endpoint. Defaults to a no-op
//     until `AnalyticsConfig` is filled in, so the shipped build makes none.
//

import Foundation
import UIKit

// MARK: - Configuration

/// Fill these in to enable self-hosted analytics. While `host`/`websiteID` are
/// nil, all analytics calls are no-ops (the app makes no analytics network calls).
enum AnalyticsConfig {
    /// e.g. URL(string: "https://analytics.yourdomain.com")
    static let host: URL? = nil
    /// Umami "website id" for this app.
    static let websiteID: String? = nil
    /// Ingestion path (Umami v2 default).
    static let ingestionPath: String = "/api/send"

    static var isConfigured: Bool { host != nil && websiteID != nil }
}

// MARK: - Events

enum AnalyticsEvent: String {
    case appOpen = "app_open"
    case appLaunch = "app_launch"
    case rewardedUnlock = "rewarded_unlock"
}

enum LaunchSource: String {
    case widget
    case inApp = "in_app"
}

// MARK: - Provider

protocol AnalyticsProvider {
    func send(event: String, properties: [String: String])
}

/// Does nothing — used when analytics is disabled or unconfigured.
struct NoopAnalyticsProvider: AnalyticsProvider {
    func send(event: String, properties: [String: String]) {}
}

/// Posts events to an Umami-compatible endpoint.
struct UmamiAnalyticsProvider: AnalyticsProvider {
    let host: URL
    let websiteID: String
    let ingestionPath: String
    let installID: String

    func send(event: String, properties: [String: String]) {
        var data = properties
        data["installId"] = installID

        let payload: [String: Any] = [
            "type": "event",
            "payload": [
                "website": websiteID,
                "hostname": "rocketlauncher",
                "url": "/\(event)",
                "name": event,
                "data": data
            ]
        ]

        guard let url = URL(string: ingestionPath, relativeTo: host),
              let body = try? JSONSerialization.data(withJSONObject: payload) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 15

        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
    }
}

// MARK: - Manager

final class AnalyticsManager {
    static let shared = AnalyticsManager()

    private var provider: AnalyticsProvider = NoopAnalyticsProvider()
    private(set) var installID: String

    private let enabledKey = "AnalyticsEnabled"

    /// Whether usage sharing is enabled. OPT-IN: missing value means disabled.
    var isEnabled: Bool {
        get { UserDefaults(suiteName: appGroupID)?.bool(forKey: enabledKey) ?? false }
        set { UserDefaults(suiteName: appGroupID)?.set(newValue, forKey: enabledKey) }
    }

    private init() {
        installID = Keychain.loadOrCreateInstallID()
        configureProvider()
    }

    private func configureProvider() {
        if let host = AnalyticsConfig.host, let websiteID = AnalyticsConfig.websiteID {
            provider = UmamiAnalyticsProvider(
                host: host,
                websiteID: websiteID,
                ingestionPath: AnalyticsConfig.ingestionPath,
                installID: installID
            )
        } else {
            provider = NoopAnalyticsProvider()
        }
    }

    /// Deletes the stored install id and generates a fresh one (Settings → Privacy).
    func resetInstallID() {
        installID = Keychain.resetInstallID()
        configureProvider()
    }

    // MARK: Logging

    func log(_ event: AnalyticsEvent, properties: [String: String] = [:]) {
        guard isEnabled, AnalyticsConfig.isConfigured else { return }
        var props = baseProperties()
        props.merge(properties) { _, new in new }
        provider.send(event: event.rawValue, properties: props)
    }

    /// Logs an app launch with the app name and full URL scheme, plus where it
    /// was tapped (widget/slot) and the local hour of day. Only sent when the
    /// user has opted in and analytics is configured.
    func logAppLaunch(scheme: String, source: LaunchSource, appName: String? = nil, widget: Int? = nil, slot: Int? = nil) {
        guard isEnabled, AnalyticsConfig.isConfigured else { return }
        let match = AppCatalog.bundled.first { $0.scheme.caseInsensitiveCompare(scheme) == .orderedSame }
            ?? AppCatalog.knownApps().first { $0.scheme.caseInsensitiveCompare(scheme) == .orderedSame }
        let name = appName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = (name?.isEmpty == false ? name! : nil) ?? match?.name ?? "custom"
        let hour = Calendar.current.component(.hour, from: Date())
        var props: [String: String] = [
            "appName": resolvedName,
            "scheme": scheme,
            "source": source.rawValue,
            "hour": String(hour),
            "timeOfDay": Self.timeOfDay(hour: hour),
            "category": Self.coarseCategory(match?.category)
        ]
        if let widget { props["widget"] = String(widget) }
        if let slot { props["slot"] = String(slot) }
        log(.appLaunch, properties: props)
    }

    private static func timeOfDay(hour: Int) -> String {
        switch hour {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<21: return "evening"
        default: return "night"
        }
    }

    func logAppOpen() {
        log(.appOpen)
    }

    /// Categories safe to record. Anything else (finance, health, dating,
    /// religion, news, …) is bucketed into "other" so we never infer sensitive
    /// interests.
    private static let safeCategories: Set<String> = [
        "social", "media", "productivity", "navigation", "shopping", "games", "utilities", "apple"
    ]

    private static func coarseCategory(_ raw: String?) -> String {
        let c = (raw ?? "custom").lowercased()
        return safeCategories.contains(c) ? c : "other"
    }

    // MARK: Base properties

    private func baseProperties() -> [String: String] {
        [
            "device": Self.deviceModelIdentifier(),
            "os": UIDevice.current.systemVersion,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?",
            "build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?",
            "region": Locale.current.region?.identifier ?? "unknown"
        ]
    }

    private static func deviceModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
        return machine
    }
}

// MARK: - Keychain (pseudonymous, resettable install id)

enum Keychain {
    private static let service = "com.Robledas.rocketlauncher.analytics"
    private static let account = "installID"

    static func loadOrCreateInstallID() -> String {
        if let existing = string(for: account) { return existing }
        return createNew()
    }

    @discardableResult
    static func resetInstallID() -> String {
        remove(account)
        return createNew()
    }

    private static func createNew() -> String {
        let id = UUID().uuidString
        set(id, for: account)
        return id
    }

    static func string(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func set(_ value: String, for key: String) -> Bool {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        // This-device-only: never restored from backups; resettable in Settings.
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }

    static func remove(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
