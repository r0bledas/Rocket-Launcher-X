//
//  PaywallView.swift
//  Rocket Launcher
//
//  Created by Raudel Alejandro on 19-07-2025.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "rocket.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .padding(.bottom, 8)
                        
                        Text("Unlock Full Potential")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Supercharge your home screen with advanced widgets and customization.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Bundle Hero Card
                    if let bundleProduct = storeManager.products.first(where: { $0.id == RocketProducts.proLifetime }) {
                        if !storeManager.purchasedProductIDs.contains(bundleProduct.id) {
                            BundleCard(product: bundleProduct) {
                                Task { await storeManager.purchase(bundleProduct) }
                            }
                        } else {
                            PurchasedCard(title: "Pro Bundle Unlocked", icon: "crown.fill")
                        }
                    } else if storeManager.isLoading {
                        ProgressView()
                            .padding()
                    }
                    
                    // Individual Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Or choose individual features")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        // Extra Widgets
                        FeatureRow(
                            productID: RocketProducts.widgets,
                            icon: "square.grid.2x2.fill",
                            color: .orange,
                            title: "Extra Widgets Pack",
                            subtitle: "Unlock Widgets 2-5"
                        )
                        
                        // Icons
                        FeatureRow(
                            productID: RocketProducts.icons,
                            icon: "app.dashed",
                            color: .green,
                            title: "Icon Feature",
                            subtitle: "Show app icons in widgets"
                        )
                        
                        // Calendar
                        FeatureRow(
                            productID: RocketProducts.calendar,
                            icon: "calendar",
                            color: .red,
                            title: "Calendar Widget",
                            subtitle: "Access the calendar widget"
                        )
                        
                        // Alignment
                        FeatureRow(
                            productID: RocketProducts.alignment,
                            icon: "text.alignleft",
                            color: .purple,
                            title: "Text Alignment",
                            subtitle: "Customize text alignment"
                        )
                    }
                    
                    // Restore Button
                    Button(action: {
                        Task { await storeManager.restorePurchases() }
                    }) {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
                .padding()
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

struct BundleCard: View {
    let product: Product
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("LIFETIME BUNDLE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .tracking(1)
                            
                            Text("Get Everything")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        Image(systemName: "crown.fill")
                            .font(.largeTitle)
                            .foregroundColor(.yellow)
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Includes all 4 features")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(product.displayPrice)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(20)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue, lineWidth: 2)
                )
                
                // Discount Badge
                Text("SAVE 30%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(8)
                    .offset(x: 10, y: -10)
                    .shadow(radius: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.top, 10) // Space for the badge
    }
}

struct PurchasedCard: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
            Text(title)
                .font(.headline)
                .foregroundColor(.green)
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

struct FeatureRow: View {
    let productID: String
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    
    @EnvironmentObject var storeManager: StoreManager
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if storeManager.purchasedProductIDs.contains(productID) || storeManager.purchasedProductIDs.contains(RocketProducts.proLifetime) {
                Image(systemName: "checkmark")
                    .foregroundColor(.green)
                    .font(.headline)
            } else {
                if let product = storeManager.products.first(where: { $0.id == productID }) {
                    Button(action: {
                        Task { await storeManager.purchase(product) }
                    }) {
                        Text(product.displayPrice)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(16)
                    }
                } else {
                    ProgressView()
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}
