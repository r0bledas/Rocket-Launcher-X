//
//  AdsManager.swift
//  Rocket Launcher
//
//  Google Mobile Ads (banner + rewarded) with ATT and UMP consent, plus the
//  temporary "watch a rewarded ad to unlock widgets for 3 days" entitlement.
//
//  Ad unit IDs and the AdMob application id are supplied via build settings
//  (see AdConfig): Debug uses Google's test IDs, Release must supply production
//  IDs. A build-time script fails Release builds that still use test IDs.
//

import Foundation
import SwiftUI
import UIKit
import GoogleMobileAds
import UserMessagingPlatform
import AppTrackingTransparency
import WidgetKit
import CryptoKit
import Security

// MARK: - Ad configuration (build-setting driven)

enum AdConfig {
    static var appID: String { info("GADApplicationIdentifier") }
    static var bannerUnit: String { info("AdBannerUnitID") }
    static var rewardedUnit: String { info("AdRewardedUnitID") }

    private static func info(_ key: String) -> String {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    /// Google's shared test publisher id (app id + test unit ids share this).
    static let testPublisher = "3940256099942544"

    static var usesTestIDs: Bool {
        appID.contains(testPublisher) || bannerUnit.contains(testPublisher) || rewardedUnit.contains(testPublisher)
    }
}

// MARK: - Temporary widget unlock entitlement (hardened, best-effort)

/// "Watch a rewarded ad to unlock widgets for `duration`."
///
/// This is a client-only entitlement and can never be fully tamper-proof. We do
/// a best-effort job: the authoritative value is an HMAC-signed record stored in
/// the Keychain (this-device-only), we detect obvious wall-clock rollback, and we
/// mirror the expiry to the app group so the widget can read it read-only.
enum RewardsEntitlement {
    /// Single source of truth for the unlock length (referenced by the Terms).
    static let duration: TimeInterval = 3 * 24 * 3600 // 3 days
    static var durationDays: Double { duration / 86_400 }

    /// Mirrored, read-only value the widget reads from the app group.
    private static let mirrorKey = "ExtraWidgetsUnlockUntil"
    private static let recordAccount = "rewards.entitlement"
    private static let hmacKeyAccount = "rewards.hmacKey"

    /// If the wall clock jumps backward by more than this, treat as tampering.
    private static let rollbackTolerance: TimeInterval = 60 * 60

    struct State: Codable {
        var until: TimeInterval
        var lastSeenWall: TimeInterval
        var lastSeenUptime: TimeInterval
    }

    static func unlockUntil() -> Date? {
        guard let state = loadState(), verify(state) else { return nil }

        let now = Date()
        // Wall clock moved backward materially → tampering; void the unlock.
        if now.timeIntervalSince1970 < state.lastSeenWall - rollbackTolerance {
            return nil
        }
        return now.timeIntervalSince1970 < state.until ? Date(timeIntervalSince1970: state.until) : nil
    }

    static func isActive() -> Bool { unlockUntil() != nil }

    /// Grants (or extends) the temporary unlock by `duration`.
    static func grant() {
        let now = Date()
        let base = max(now, unlockUntil() ?? now)
        let state = State(
            until: base.addingTimeInterval(duration).timeIntervalSince1970,
            lastSeenWall: now.timeIntervalSince1970,
            lastSeenUptime: ProcessInfo.processInfo.systemUptime
        )
        save(state)
        mirror(Date(timeIntervalSince1970: state.until))
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func clear() {
        SecureStore.remove(recordAccount)
        UserDefaults(suiteName: appGroupID)?.removeObject(forKey: mirrorKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: Persistence

    private static func save(_ state: State) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        let sig = hmac(data)
        SecureStore.set(data.base64EncodedString() + "|" + sig, for: recordAccount)
    }

    private static func loadState() -> State? {
        guard let raw = SecureStore.string(for: recordAccount) else { return nil }
        let parts = raw.split(separator: "|", maxSplits: 1).map(String.init)
        guard parts.count == 2,
              let data = Data(base64Encoded: parts[0]) else { return nil }
        return try? JSONDecoder().decode(State.self, from: data)
    }

    private static func verify(_ state: State) -> Bool {
        guard let raw = SecureStore.string(for: recordAccount) else { return false }
        let parts = raw.split(separator: "|", maxSplits: 1).map(String.init)
        guard parts.count == 2, let data = Data(base64Encoded: parts[0]) else { return false }
        return hmac(data) == parts[1]
    }

    private static func hmac(_ data: Data) -> String {
        let key = secureHMACKey()
        let mac = HMAC<SHA256>.authenticationCode(for: data, using: key)
        return mac.map { String(format: "%02x", $0) }.joined()
    }

    private static func secureHMACKey() -> SymmetricKey {
        if let b64 = SecureStore.string(for: hmacKeyAccount), let data = Data(base64Encoded: b64) {
            return SymmetricKey(data: data)
        }
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data($0) }
        SecureStore.set(data.base64EncodedString(), for: hmacKeyAccount)
        return key
    }

    private static func mirror(_ until: Date) {
        UserDefaults(suiteName: appGroupID)?.set(until.timeIntervalSince1970, forKey: mirrorKey)
    }
}

// MARK: - AdsManager

final class AdsManager: NSObject, ObservableObject {
    static let shared = AdsManager()

    @Published var isRewardedReady = false
    @Published var isRewardedLoading = false
    /// Mirrors UMP's `canRequestAds` so views can gate requests.
    @Published var canRequestAds = false
    /// UMP requires a persistent "Privacy options" entry point in the UI.
    @Published var privacyOptionsRequired = false

    private var rewardedAd: RewardedAd?
    private var rewardHandler: (() -> Void)?
    private var didStart = false

    private override init() { super.init() }

    // MARK: Lifecycle

    /// Consent first, then (only if allowed) start the SDK → ATT → preload.
    func start() {
        guard !didStart else { return }
        didStart = true

        let parameters = RequestParameters()
        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.refreshConsentState()
                self.presentConsentFormIfNeeded(attempt: 0)
            }
        }
    }

    private func refreshConsentState() {
        canRequestAds = ConsentInformation.shared.canRequestAds
        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    private func presentConsentFormIfNeeded(attempt: Int) {
        guard let topVC = UIApplication.shared.topViewController else {
            // A3: don't silently skip consent if the VC isn't ready yet — retry.
            guard attempt < 6 else { finishConsentFlow(); return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.presentConsentFormIfNeeded(attempt: attempt + 1)
            }
            return
        }
        ConsentForm.loadAndPresentIfRequired(from: topVC) { [weak self] _ in
            self?.finishConsentFlow()
        }
    }

    private func finishConsentFlow() {
        refreshConsentState()
        // Only initialize the SDK if consent permits ad requests.
        guard ConsentInformation.shared.canRequestAds else { return }
        MobileAds.shared.start { [weak self] _ in
            DispatchQueue.main.async { self?.requestATT() }
        }
    }

    private func requestATT() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async { [weak self] in
                    self?.refreshConsentState()
                    guard AdConfig.canLoadAds else { return }
                    self?.loadRewarded()
                }
            }
        } else {
            loadRewarded()
        }
    }

    // MARK: Privacy options

    func presentPrivacyOptions() {
        guard let topVC = UIApplication.shared.topViewController else { return }
        ConsentForm.presentPrivacyOptionsForm(from: topVC) { [weak self] _ in
            self?.refreshConsentState()
        }
    }

    /// Debug only: clears the stored consent so the form can be re-tested.
    func resetConsent() {
        #if DEBUG
        ConsentInformation.shared.reset()
        refreshConsentState()
        #endif
    }

    // MARK: Rewarded

    func loadRewarded() {
        guard AdConfig.canLoadAds else { return }
        guard rewardedAd == nil, !isRewardedLoading else { return }
        isRewardedLoading = true
        RewardedAd.load(with: AdConfig.rewardedUnit, request: Request()) { [weak self] ad, error in
            DispatchQueue.main.async {
                self?.isRewardedLoading = false
                self?.rewardedAd = ad
                ad?.fullScreenContentDelegate = self
                self?.isRewardedReady = (ad != nil && error == nil)
            }
        }
    }

    /// Presents the rewarded ad. `onReward` fires only if the user earned it;
    /// `onUnavailable` fires when no ad can be shown (no reward granted).
    func presentRewarded(onReward: @escaping () -> Void, onUnavailable: @escaping () -> Void) {
        guard AdConfig.canLoadAds, let ad = rewardedAd, let topVC = UIApplication.shared.topViewController else {
            loadRewarded()
            onUnavailable()
            return
        }
        rewardHandler = onReward
        ad.present(from: topVC) { [weak self] in
            self?.rewardHandler?()
            self?.rewardHandler = nil
            AnalyticsManager.shared.log(.rewardedUnlock)
        }
    }
}

extension AdsManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        rewardedAd = nil
        isRewardedReady = false
        loadRewarded()
    }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        rewardedAd = nil
        isRewardedReady = false
        loadRewarded()
    }
}

extension AdConfig {
    /// Whether ads may be requested right now (consent + configured IDs).
    static var canLoadAds: Bool {
        ConsentInformation.shared.canRequestAds && !bannerUnit.isEmpty && !rewardedUnit.isEmpty
    }
}

// MARK: - Banner (SwiftUI)

struct BannerAdView: UIViewRepresentable {
    /// Observes consent so we don't load before ads are permitted.
    @ObservedObject var ads: AdsManager

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = AdConfig.bannerUnit
        banner.delegate = context.coordinator
        banner.rootViewController = UIApplication.shared.topViewController
        context.coordinator.loadIfPossible(banner, canRequestAds: ads.canRequestAds)
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        context.coordinator.loadIfPossible(uiView, canRequestAds: ads.canRequestAds)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, BannerViewDelegate {
        private var loaded = false
        func loadIfPossible(_ banner: BannerView, canRequestAds: Bool) {
            guard canRequestAds, !loaded, AdConfig.canLoadAds else { return }
            loaded = true
            banner.load(Request())
        }
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {}
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            loaded = false
        }
    }
}

// MARK: - SecureStore (Keychain, this-device-only)

enum SecureStore {
    private static let service = "com.Robledas.rocketlauncher.secure"

    static func string(for account: String) -> String? {
        var query = baseQuery(account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func set(_ value: String, for account: String) -> Bool {
        SecItemDelete(baseQuery(account) as CFDictionary)
        var attributes = baseQuery(account)
        attributes[kSecValueData as String] = Data(value.utf8)
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }

    static func remove(_ account: String) {
        SecItemDelete(baseQuery(account) as CFDictionary)
    }

    private static func baseQuery(_ account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

// MARK: - Top view controller

extension UIApplication {
    var topViewController: UIViewController? {
        let keyWindow = connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first { $0.isKeyWindow } ?? windows.first { $0.isKeyWindow }
        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
