//
//  Analytics.swift
//  Rocket Launcher
//
//  Privacy-first, pseudonymous usage analytics.
//
//  Design goals:
//   - Minimal data: aggregate app-launch events only. Never log raw custom URL
//     schemes a user typed (they can contain private data) — resolve to a known
//     catalog app or a generic "custom" bucket.
//   - Pseudonymous: a random, resettable install id stored in the Keychain.
//     No IDFA, names, emails, precise location, or content.
//   - Self-hosted: posts to an Umami-compatible endpoint. Defaults to a no-op
//     until `AnalyticsConfig` is filled in, so the app runs with zero network.
//   - Opt-out: users can disable it in Settings.
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
}

// MARK: - Events

enum AnalyticsEvent: String {
    case appOpen = "app_open"
    case appLaunch = "app_launch"
    case rewardedUnlock = "rewarded_unlock"
    case adShown = "ad_shown"
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
    private let installID: String

    private let optOutKey = "AnalyticsOptOut"

    /// Whether usage sharing is enabled. Persisted in the shared app group so
    /// the widget could read it too.
    var isEnabled: Bool {
        get { !(UserDefaults(suiteName: appGroupID)?.bool(forKey: optOutKey) ?? false) }
        set { UserDefaults(suiteName: appGroupID)?.set(!newValue, forKey: optOutKey) }
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

    // MARK: Logging

    func log(_ event: AnalyticsEvent, properties: [String: String] = [:]) {
        guard isEnabled else { return }
        var props = baseProperties()
        props.merge(properties) { _, new in new }
        provider.send(event: event.rawValue, properties: props)
    }

    /// Logs an app launch, resolving the scheme to a catalog app (never the raw
    /// custom scheme) to protect users who typed private schemes.
    func logAppLaunch(scheme: String, source: LaunchSource) {
        guard isEnabled else { return }
        let match = AppCatalog.bundled.first { $0.scheme.caseInsensitiveCompare(scheme) == .orderedSame }
        let props: [String: String] = [
            "app": match?.name ?? "custom",
            "category": match?.category ?? "custom",
            "source": source.rawValue
        ]
        log(.appLaunch, properties: props)
    }

    func logAppOpen() {
        log(.appOpen)
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

// MARK: - Keychain (pseudonymous install id)

enum Keychain {
    private static let service = "com.Robledas.rocketlauncher.analytics"
    private static let account = "installID"

    static func loadOrCreateInstallID() -> String {
        if let existing = string(for: account) { return existing }
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
        return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }
}
