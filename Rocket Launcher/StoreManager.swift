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
}

@MainActor
class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // App Group ID for sharing status with widgets
    private let appGroupID = "group.rocketlauncher"
    
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
            let products = try await Product.products(for: [RocketProducts.proLifetime])
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
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                print("✅ StoreManager: Purchase successful")
                // Verify the transaction
                let transaction = try checkVerified(verification)
                
                // Update purchased status
                await updatePurchasedProducts()
                
                // Always finish the transaction
                await transaction.finish()
                
            case .userCancelled:
                print("⚠️ StoreManager: User cancelled")
            case .pending:
                print("⏳ StoreManager: Transaction pending")
            @unknown default:
                print("❓ StoreManager: Unknown purchase result")
            }
            
        } catch {
            print("❌ StoreManager: Purchase failed: \(error)")
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Restore / Verification
    
    func updatePurchasedProducts() async {
        var purchased = Set<String>()
        
        // Iterate through the user's current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Check if this is our pro product
                if transaction.productID == RocketProducts.proLifetime {
                    // Check for revocation
                    if transaction.revocationDate == nil {
                        purchased.insert(transaction.productID)
                    }
                }
            } catch {
                print("❌ StoreManager: Verification failed: \(error)")
            }
        }
        
        self.purchasedProductIDs = purchased
        
        // Sync with App Group for Widgets
        syncToAppGroup(isPro: purchased.contains(RocketProducts.proLifetime))
    }
    
    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedProducts()
    }
    
    func resetStatus() {
        purchasedProductIDs.removeAll()
        syncToAppGroup(isPro: false)
        print("🔄 StoreManager: Status reset to non-pro")
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
    
    private func syncToAppGroup(isPro: Bool) {
        if let userDefaults = UserDefaults(suiteName: appGroupID) {
            // We use a specific key that widgets check
            // Note: In a real app, you might want to use Keychain for better security,
            // but for this implementation, we'll stick to UserDefaults as per the existing architecture.
            // We'll use a new key "IsProUser" to distinguish from the old "HasPurchased..." flags
            userDefaults.set(isPro, forKey: "IsProUser")
            
            // Also update the legacy flags if Pro is active, to maintain backward compatibility if needed
            if isPro {
                userDefaults.set(true, forKey: "HasPurchasedIconFeature")
                // Add other legacy flags here if necessary
            }
            
            print("🔄 StoreManager: Synced Pro status (\(isPro)) to App Group")
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
