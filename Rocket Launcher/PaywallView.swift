import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.dismiss) var dismiss
    
    private var lifetimeProduct: Product? {
        storeManager.products.first(where: { $0.id == RocketProducts.proLifetime })
    }
    
    private var foundersProduct: Product? {
        storeManager.products.first(where: { $0.id == RocketProducts.futurePremiumFoundersYearly })
    }
    
    private var yearlyProduct: Product? {
        storeManager.products.first(where: { $0.id == RocketProducts.futurePremiumYearly })
    }
    
    private var monthlyProduct: Product? {
        storeManager.products.first(where: { $0.id == RocketProducts.futurePremiumMonthly })
    }
    
    private var legacyProducts: [Product] {
        storeManager.products.filter {
            [RocketProducts.widgets, RocketProducts.icons, RocketProducts.calendar, RocketProducts.alignment].contains($0.id)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Image(systemName: "rocket.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.blue)
                        Text("Choose your plan")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Free, Lifetime, or Future Premium")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 16)
                    
                    TierCard(
                        title: "Free",
                        subtitle: "Core launcher features",
                        badge: nil,
                        buttonTitle: "Continue Free",
                        isPurchased: true,
                        color: .gray,
                        action: { dismiss() }
                    )
                    
                    if let lifetimeProduct {
                        TierCard(
                            title: "All Features Lifetime",
                            subtitle: "Bulk discounted unlock for current premium features",
                            badge: "One-time",
                            buttonTitle: lifetimeProduct.displayPrice,
                            isPurchased: storeManager.hasLifetimeAccess,
                            color: .blue,
                            action: { Task { await storeManager.purchase(lifetimeProduct) } }
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Future Premium Subscription")
                            .font(.headline)
                        Text("Unlock future premium drops while active")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Save more with yearly billing")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        if storeManager.hasFuturePremiumSubscription {
                            PurchasedCard(title: storeManager.hasFoundersSubscription ? "Founders Subscription Active" : "Future Premium Active", icon: "checkmark.seal.fill")
                        } else {
                            if storeManager.isFoundersEligible, let foundersProduct {
                                Button(action: {
                                    Task { await storeManager.purchase(foundersProduct) }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Founders Offer (one-time)")
                                                .font(.subheadline).bold()
                                            Text("Discount continues while subscription remains active")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text(foundersProduct.displayPrice)
                                            .fontWeight(.bold)
                                    }
                                    .padding(12)
                                    .background(Color.orange.opacity(0.15))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange, lineWidth: 1))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                                
                                Button("Not now (hide one-time offer)") {
                                    storeManager.markFoundersOfferConsumed()
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            
                            if let yearlyProduct {
                                SubscriptionRow(title: "Yearly", product: yearlyProduct) {
                                    Task { await storeManager.purchase(yearlyProduct) }
                                }
                            }
                            
                            if let monthlyProduct {
                                SubscriptionRow(title: "Monthly", product: monthlyProduct) {
                                    Task { await storeManager.purchase(monthlyProduct) }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                    
                    if !legacyProducts.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Legacy Individual Unlocks")
                                .font(.headline)
                            Text("Kept for backward compatibility")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ForEach(legacyProducts, id: \.id) { product in
                                Button(action: {
                                    Task { await storeManager.purchase(product) }
                                }) {
                                    HStack {
                                        Text(product.displayName)
                                        Spacer()
                                        Text(product.displayPrice)
                                            .fontWeight(.bold)
                                    }
                                    .padding(10)
                                    .background(Color.blue.opacity(0.08))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(16)
                    }
                    
                    Button(action: {
                        Task { await storeManager.restorePurchases() }
                    }) {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
                .padding()
            }
            .onAppear {
                Analytics.track("paywall_viewed")
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct TierCard: View {
    let title: String
    let subtitle: String
    let badge: String?
    let buttonTitle: String
    let isPurchased: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                if let badge {
                    Text(badge)
                        .font(.caption).bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
            if isPurchased {
                PurchasedCard(title: "Unlocked", icon: "checkmark.circle.fill")
            } else {
                Button(action: action) {
                    Text(buttonTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(color)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

private struct SubscriptionRow: View {
    let title: String
    let product: Product
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .fontWeight(.semibold)
                    Text(product.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(product.displayPrice)
                    .fontWeight(.bold)
            }
            .padding(10)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct PurchasedCard: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.green)
            Spacer()
        }
        .padding(10)
        .background(Color.green.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}
