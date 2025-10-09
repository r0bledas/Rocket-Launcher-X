//
//  SalesManager.swift (iOS)
//  Rocket Launcher
//

import Foundation
import WatchConnectivity

struct SalesItem: Codable, Equatable, Identifiable {
    let id: String
    var name: String
    var unitPrice: Double
    var unitCost: Double
    var count: Int
}

final class SalesManager: ObservableObject {
    @Published var items: [SalesItem]
    @Published var lastResetDate: Date
    
    private let storageKey = "SalesState_v1"
    
    struct PersistedState: Codable {
        var items: [SalesItem]
        var lastResetDate: Date
    }
    
    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let state = try? JSONDecoder().decode(PersistedState.self, from: data) {
            self.items = state.items
            self.lastResetDate = state.lastResetDate
        } else {
            self.items = [
                SalesItem(id: "kitkat", name: "KitKat", unitPrice: 15.0, unitCost: 11.19, count: 0),
                SalesItem(id: "oreo", name: "Oreo", unitPrice: 20.0, unitCost: 11.43, count: 0)
            ]
            self.lastResetDate = Date()
            persist()
        }
    }
    
    func applyRemoteState(items: [SalesItem], lastResetDate: Date) {
        self.items = items
        self.lastResetDate = lastResetDate
        persist()
    }
    
    func increment(itemId: String) { update(itemId) { $0 + 1 } }
    func decrement(itemId: String) { update(itemId) { max(0, $0 - 1) } }
    
    private func update(_ itemId: String, transform: (Int) -> Int) {
        guard let idx = items.firstIndex(where: { $0.id == itemId }) else { return }
        items[idx].count = transform(items[idx].count)
        persist()
    }
    
    func resetCounts() {
        for i in items.indices { items[i].count = 0 }
        lastResetDate = Date()
        persist()
    }
    
    var totalUnits: Int { items.reduce(0) { $0 + $1.count } }
    var totalRevenue: Double { items.reduce(0) { $0 + (Double($1.count) * $1.unitPrice) } }
    var totalProfit: Double { items.reduce(0) { $0 + (Double($1.count) * ($1.unitPrice - $1.unitCost)) } }
    
    private func persist() {
        let state = PersistedState(items: items, lastResetDate: lastResetDate)
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        
        // Push to Apple Watch if available
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.activationState == .activated && session.isPaired && session.isWatchAppInstalled {
                let payload: [String: Any] = [
                    "items": (try? JSONEncoder().encode(items)) ?? Data(),
                    "lastResetDate": lastResetDate.timeIntervalSince1970
                ]
                session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
            }
        }
    }
}



