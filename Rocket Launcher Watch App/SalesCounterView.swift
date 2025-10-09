//
//  SalesCounterView.swift
//  Rocket Launcher Watch App
//
//  Simple sales counter UI for KitKat and Oreo on watchOS.
//

import SwiftUI
import WatchKit

struct SalesCounterView: View {
    @StateObject private var manager = SalesManager()
    @State private var showingResetConfirm = false
    
    private func currency(_ value: Double) -> String {
        // MXN formatting without locale overhead to keep it tiny on watch
        String(format: "MXN %.2f", value)
    }
    
    var body: some View {
        ScrollView { // Make content scrollable to keep controls accessible
            VStack(spacing: 6) {
                // Title
                HStack {
                    Text("Sales Counter")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                
                // Items list
                ForEach(manager.items) { item in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text("Price \(currency(item.unitPrice))")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .layoutPriority(1)
                        Spacer(minLength: 6)
                        HStack(spacing: 6) {
                            Button(action: {
                                manager.decrement(itemId: item.id)
                                WKInterfaceDevice.current().play(.click)
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 12, weight: .bold))
                                    .frame(width: 26, height: 26)
                                    .background(RoundedRectangle(cornerRadius: 6).stroke(Color.blue, lineWidth: 1))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text("\(item.count)")
                                .font(.system(size: 14, weight: .bold))
                                .frame(minWidth: 22)
                                .foregroundColor(.white)
                            
                            Button(action: {
                                manager.increment(itemId: item.id)
                                WKInterfaceDevice.current().play(.success)
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                    .frame(width: 26, height: 26)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.blue)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(white: 0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 8)
                
                // Summary
                VStack(spacing: 4) {
                    HStack {
                        Text("Units")
                        Spacer()
                        Text("\(manager.totalUnits)")
                    }
                    HStack {
                        Text("Revenue")
                        Spacer()
                        Text(currency(manager.totalRevenue))
                    }
                    HStack {
                        Text("Profit")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Text(currency(manager.totalProfit))
                            .font(.system(size: 13, weight: .bold))
                    }
                }
                .font(.system(size: 11))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(white: 0.08))
                .cornerRadius(10)
                .padding(.horizontal, 8)
                
                // Reset button and navigation hint
                VStack(spacing: 8) {
                    Button(action: {
                        WKInterfaceDevice.current().play(.click)
                        showingResetConfirm = true
                    }) {
                        Text("Reset Today")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(Capsule().fill(Color.red))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 16)

                    HStack(spacing: 4) {
                        Text("Web")
                            .font(.system(size: 9, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 7))
                    }
                    .foregroundColor(.secondary)
                    .padding(.bottom, 10)
                }
                .padding(.top, -6)
            }
            .background(Color.black)
        }
        .alert("Reset counts?", isPresented: $showingResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    WKInterfaceDevice.current().play(.failure)
                    manager.resetCounts()
                }
            } message: {
                Text("This will set all items to 0 for today.")
            }
        .padding(.top, -8) // pull content closer to status time
    }
}

#Preview {
    SalesCounterView()
}


