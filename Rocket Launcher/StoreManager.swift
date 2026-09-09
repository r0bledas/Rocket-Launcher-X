//
//  StoreManager.swift
//  Rocket Launcher
//
//  Created by Raudel Alejandro on 19-07-2025.
//

import Foundation
import StoreKit

// Define our product IDs
public enum RocketProducts {
    static let proLifetime = "com.rocketlauncher.pro.lifetime"
    static let widgets = "com.rocketlauncher.feature.widgets"
    static let icons = "com.rocketlauncher.feature.icons"
    static let calendar = "com.rocketlauncher.feature.calendar"
    static let alignment = "com.rocketlauncher.feature.alignment"
    static let futurePremiumMonthly = "com.rocketlauncher.future.monthly"
    static let futurePremiumYearly = "com.rocketlauncher.future.yearly"
    static let futurePremiumFoundersYearly = "com.rocketlauncher.future.founders.yearly"
    
    static let legacyNonConsumables = [proLifetime, widgets, icons, calendar, alignment]
    static let subscriptions = [futurePremiumMonthly, futurePremiumYearly, futurePremiumFoundersYearly]
    static let all = legacyNonConsumables + subscriptions
}

@MainActor
class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasLifetimeAccess = false
    @Published var hasFuturePremiumSubscription = false
    @Published var hasFoundersSubscription = false
    @Published var isFoundersEligible = false
    
    // App Group ID for sharing status with widgets
    private let appGroupID = "group.rocketlauncher"
    private let foundersOfferConsumedKey = "FoundersOfferConsumed"
    
    var updateListenerTask: Task<Void, Error>? = nil

    init() {
        // Start a listener for transaction updates
        updateListenerTask = Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    await updatePurchasedProducts()
                    await transaction.finish()
                    print("✅ StoreManager: Transaction updated: \(transaction.productID)")
                } catch {
                    print("❌ StoreManager: Transaction verification failed")
                }
            }
        }
        
        // Check initial status
        Task {
            await updatePurchasedProducts()
            await loadProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Fetching
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let products = try await Product.products(for: RocketProducts.all)
            self.products = products
            print("✅ StoreManager: Found \(products.count) products")
        } catch {
            print("❌ StoreManager: Failed to load products: \(error)")
            errorMessage = "Failed to load products. Please try again."
        }
        
        isLoading = false
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async {
        isLoading = true
        Analytics.track("purchase_started", properties: ["product_id": product.id])
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                print("✅ StoreManager: Purchase successful")
                // Verify the transaction
                let transaction = try checkVerified(verification)
                Analytics.track("purchase_completed", properties: ["product_id": transaction.productID])
                if transaction.productID == RocketProducts.futurePremiumFoundersYearly {
                    markFoundersOfferConsumed()
                }
                
                // Update purchased status
                await updatePurchasedProducts()
                
                // Always finish the transaction
                await transaction.finish()
                
            case .userCancelled:
                print("⚠️ StoreManager: User cancelled")
                Analytics.track("purchase_cancelled", properties: ["product_id": product.id])
            case .pending:
                print("⏳ StoreManager: Transaction pending")
                Analytics.track("purchase_pending", properties: ["product_id": product.id])
            @unknown default:
                print("❓ StoreManager: Unknown purchase result")
            }
            
        } catch {
            print("❌ StoreManager: Purchase failed: \(error)")
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            Analytics.track("purchase_failed", properties: ["product_id": product.id])
        }
        
        isLoading = false
    }
    
    // MARK: - Restore / Verification
    
    func updatePurchasedProducts() async {
        var purchased = Set<String>()
        let now = Date()
        
        // Iterate through the user's current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Check if this is one of our products and currently active
                if RocketProducts.all.contains(transaction.productID),
                   transaction.revocationDate == nil {
                    if let expiration = transaction.expirationDate {
                        if expiration > now {
                            purchased.insert(transaction.productID)
                        }
                    } else {
                        purchased.insert(transaction.productID)
                    }
                }
            } catch {
                print("❌ StoreManager: Verification failed: \(error)")
            }
        }
        
        self.purchasedProductIDs = purchased
        self.hasLifetimeAccess = purchased.contains(RocketProducts.proLifetime)
        self.hasFoundersSubscription = purchased.contains(RocketProducts.futurePremiumFoundersYearly)
        self.hasFuturePremiumSubscription =
            purchased.contains(RocketProducts.futurePremiumMonthly) ||
            purchased.contains(RocketProducts.futurePremiumYearly) ||
            hasFoundersSubscription
        self.isFoundersEligible = hasLifetimeAccess && !hasFoundersOfferConsumed()
        
        // Sync with App Group for Widgets
        syncToAppGroup(isPro: hasLifetimeAccess)
    }
    
    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedProducts()
    }
    
    func resetStatus() {
        purchasedProductIDs.removeAll()
        hasLifetimeAccess = false
        hasFuturePremiumSubscription = false
        hasFoundersSubscription = false
        isFoundersEligible = false
        syncToAppGroup(isPro: false)
        print("🔄 StoreManager: Status reset to non-pro")
    }
    
    func products(for ids: [String]) -> [Product] {
        products.filter { ids.contains($0.id) }
    }
    
    func markFoundersOfferConsumed() {
        UserDefaults(suiteName: appGroupID)?.set(true, forKey: foundersOfferConsumedKey)
        isFoundersEligible = false
    }
    
    private func hasFoundersOfferConsumed() -> Bool {
        UserDefaults(suiteName: appGroupID)?.bool(forKey: foundersOfferConsumedKey) ?? false
    }
    
    // MARK: - Helper
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        // Check if the transaction passes StoreKit verification
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    private func syncToAppGroup(isPro: Bool) { // isPro argument is now ignored in favor of granular checks, but kept for signature compatibility if needed, though we should really just use internal state
        if let userDefaults = UserDefaults(suiteName: appGroupID) {
            let hasBundle = hasLifetimeAccess
            let hasFutureSubscription = hasFuturePremiumSubscription
            let hasFounders = hasFoundersSubscription
            let hasAnyPaid = !purchasedProductIDs.isEmpty
            
            // Determine individual feature status (Bundle OR Individual Purchase)
            let hasWidgets = hasBundle || purchasedProductIDs.contains(RocketProducts.widgets)
            let hasIcons = hasBundle || purchasedProductIDs.contains(RocketProducts.icons)
            let hasCalendar = hasBundle || purchasedProductIDs.contains(RocketProducts.calendar)
            let hasAlignment = hasBundle || purchasedProductIDs.contains(RocketProducts.alignment)
            
            // Update App Group Flags
            userDefaults.set(hasBundle, forKey: "IsProUser") // Legacy/Global flag
            userDefaults.set(hasWidgets, forKey: "HasPurchasedExtraWidgets")
            userDefaults.set(hasIcons, forKey: "HasPurchasedIconFeature")
            userDefaults.set(hasCalendar, forKey: "HasPurchasedCalendar")
            userDefaults.set(hasAlignment, forKey: "HasPurchasedTextAlignment")
            userDefaults.set(hasFutureSubscription, forKey: "HasFuturePremiumSubscription")
            userDefaults.set(hasFounders, forKey: "HasFoundersSubscription")
            userDefaults.set(isFoundersEligible, forKey: "IsFoundersEligible")
            userDefaults.set(hasBundle || hasFutureSubscription, forKey: "HasPremiumCustomLinks")
            userDefaults.set(!hasAnyPaid, forKey: "ShowAds")
            
            print("🔄 StoreManager: Synced status to App Group")
            print("   - Bundle: \(hasBundle)")
            print("   - Widgets: \(hasWidgets)")
            print("   - Icons: \(hasIcons)")
            print("   - Calendar: \(hasCalendar)")
            print("   - Alignment: \(hasAlignment)")
            print("   - Future Premium Subscription: \(hasFutureSubscription)")
            print("   - Founders Subscription: \(hasFounders)")
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
