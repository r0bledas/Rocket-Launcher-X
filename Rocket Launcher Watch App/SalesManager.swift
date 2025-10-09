//
//  SalesManager.swift
//  Rocket Launcher Watch App
//
//  Lightweight sales state and persistence for watchOS.
//

import Foundation
import Combine
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
            // Defaults: KitKat piece, Oreo pack
            self.items = [
                SalesItem(id: "kitkat", name: "KitKat", unitPrice: 15.0, unitCost: 11.19, count: 0),
                SalesItem(id: "oreo", name: "Oreo", unitPrice: 20.0, unitCost: 11.43, count: 0)
            ]
            self.lastResetDate = Date()
            persist()
        }
    }
    
    func increment(itemId: String) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else { return }
        items[index].count += 1
        persist()
    }
    
    func decrement(itemId: String) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else { return }
        items[index].count = max(0, items[index].count - 1)
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
        // Push to iPhone if available
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.activationState == .activated {
                let payload: [String: Any] = [
                    "items": (try? JSONEncoder().encode(items)) ?? Data(),
                    "lastResetDate": lastResetDate.timeIntervalSince1970
                ]
                session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
            } else {
                session.activate()
            }
        }
    }
}

// Watch receiver of iPhone updates
final class SalesWatchReceiver: NSObject, WCSessionDelegate {
    static let shared = SalesWatchReceiver()
    private override init() { super.init(); activate() }
    
    private func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let itemsData = message["items"] as? Data,
              let items = try? JSONDecoder().decode([SalesItem].self, from: itemsData),
              let ts = message["lastResetDate"] as? TimeInterval else { return }
        let date = Date(timeIntervalSince1970: ts)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .salesSyncIncoming, object: nil, userInfo: [
                "items": items,
                "lastResetDate": date
            ])
        }
    }
}

extension Notification.Name { static let salesSyncIncoming = Notification.Name("salesSyncIncoming") }


