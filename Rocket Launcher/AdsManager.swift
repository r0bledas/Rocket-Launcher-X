//
//  AdsManager.swift
//  Rocket Launcher
//
//  Google Mobile Ads (banner + rewarded) with ATT and UMP consent, plus the
//  temporary "watch a rewarded ad to unlock widgets for 3 days" entitlement.
//
//  All ad unit IDs are Google's official test IDs. Replace them (and the
//  GADApplicationIdentifier in Info.plist) with your real AdMob IDs before
//  shipping.
//

import Foundation
import SwiftUI
import UIKit
import GoogleMobileAds
import UserMessagingPlatform
import AppTrackingTransparency
import WidgetKit

enum AdUnits {
    // Google test IDs — replace before release.
    static let banner = "ca-app-pub-3940256099942544/2934735716"
    static let rewarded = "ca-app-pub-3940256099942544/1712485313"
}

// MARK: - Temporary widget unlock entitlement

enum RewardsEntitlement {
    private static let key = "ExtraWidgetsUnlockUntil"
    static let duration: TimeInterval = 3 * 24 * 3600 // 3 days

    static func unlockUntil() -> Date? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let ts = defaults.object(forKey: key) as? Double, ts > 0 else { return nil }
        return Date(timeIntervalSince1970: ts)
    }

    static func isActive() -> Bool {
        guard let until = unlockUntil() else { return false }
        return until > Date()
    }

    /// Grants (or extends) the temporary unlock by `duration`.
    static func grant(days: Double = 3) {
        let base = max(Date(), unlockUntil() ?? Date())
        let until = base.addingTimeInterval(days * 24 * 3600)
        UserDefaults(suiteName: appGroupID)?.set(until.timeIntervalSince1970, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func clear() {
        UserDefaults(suiteName: appGroupID)?.removeObject(forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - AdsManager

final class AdsManager: NSObject, ObservableObject {
    static let shared = AdsManager()

    @Published var isRewardedReady = false
    @Published var isRewardedLoading = false

    private var rewardedAd: RewardedAd?
    private var rewardHandler: (() -> Void)?

    private override init() { super.init() }

    // MARK: Lifecycle

    /// Starts the SDK, then runs consent → ATT → preload.
    func start() {
        MobileAds.shared.start { [weak self] _ in
            self?.requestConsentThenATT()
        }
    }

    private func requestConsentThenATT() {
        let parameters = RequestParameters()
        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self, let topVC = UIApplication.shared.topViewController else { return }
                ConsentForm.loadAndPresentIfRequired(from: topVC) { _ in
                    self.requestATT()
                }
            }
        }
    }

    private func requestATT() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async { self.loadRewarded() }
            }
        } else {
            loadRewarded()
        }
    }

    // MARK: Rewarded

    func loadRewarded() {
        guard rewardedAd == nil else { return }
        isRewardedLoading = true
        RewardedAd.load(with: AdUnits.rewarded, request: Request()) { [weak self] ad, error in
            DispatchQueue.main.async {
                self?.isRewardedLoading = false
                self?.rewardedAd = ad
                ad?.fullScreenContentDelegate = self
                self?.isRewardedReady = (ad != nil)
                if error != nil { self?.isRewardedReady = false }
            }
        }
    }

    /// Presents the rewarded ad; `onReward` fires only if the user earned it.
    func presentRewarded(onReward: @escaping () -> Void) {
        guard let ad = rewardedAd, let topVC = UIApplication.shared.topViewController else {
            onReward() // No fill / not ready — don't block the user.
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

// MARK: - Banner (SwiftUI)

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        banner.delegate = context.coordinator
        banner.rootViewController = UIApplication.shared.topViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, BannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {}
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {}
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
