//
//  SalesCounterView.swift (iOS)
//  Rocket Launcher
//

import SwiftUI
import WatchConnectivity

final class SalesSyncCoordinator: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = SalesSyncCoordinator()
    @Published var lastReceived: Date = .distantPast
    
    private override init() { super.init(); activate() }
    
    private func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
    
    func send(state: SalesManager.PersistedState) {
        guard WCSession.default.isPaired, WCSession.default.isWatchAppInstalled else { return }
        let payload: [String: Any] = [
            "items": (try? JSONEncoder().encode(state.items)) ?? Data(),
            "lastResetDate": state.lastResetDate.timeIntervalSince1970
        ]
        WCSession.default.sendMessage(payload, replyHandler: nil, errorHandler: nil)
    }
    
    // Receive from watch
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
            self.lastReceived = Date()
        }
    }
}

extension Notification.Name { static let salesSyncIncoming = Notification.Name("salesSyncIncoming") }

// Watch receiver for iOS app
final class SalesIOSReceiver: NSObject, WCSessionDelegate {
    static let shared = SalesIOSReceiver()
    private override init() { super.init(); activate() }
    
    private func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
    
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

struct SalesCounterView: View {
    @StateObject private var manager = SalesManager()
    @State private var showingResetConfirm = false
    @StateObject private var sync = SalesSyncCoordinator.shared
    
    private func currency(_ value: Double) -> String { String(format: "MXN %.2f", value) }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack {
                    Text("Sales Counter")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                ForEach(manager.items) { item in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name).font(.headline).foregroundColor(.white)
                            Text("Price \(currency(item.unitPrice))").font(.caption).foregroundColor(.secondary)
                        }
                        .layoutPriority(1)
                        Spacer()
                        Button(action: { manager.decrement(itemId: item.id); pushState() }) {
                            Image(systemName: "minus").frame(width: 32, height: 32).background(RoundedRectangle(cornerRadius: 8).stroke(Color.blue))
                        }
                        .buttonStyle(PlainButtonStyle())
                        Text("\(item.count)").font(.headline).foregroundColor(.white).frame(minWidth: 28)
                        Button(action: { manager.increment(itemId: item.id); pushState() }) {
                            Image(systemName: "plus").frame(width: 32, height: 32).background(RoundedRectangle(cornerRadius: 8).fill(Color.blue))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 12)
                
                VStack(spacing: 6) {
                    HStack { Text("Units"); Spacer(); Text("\(manager.totalUnits)") }
                    HStack { Text("Revenue"); Spacer(); Text(currency(manager.totalRevenue)) }
                    HStack { Text("Profit").bold(); Spacer(); Text(currency(manager.totalProfit)).bold() }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(12)
                .padding(.horizontal, 12)
                
                Button(action: { showingResetConfirm = true }) {
                    Text("Reset Today").font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding().background(Color.red).cornerRadius(12)
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 20)
            .background(Color.black)
        }
        .background(Color.black.ignoresSafeArea())
        .onReceive(NotificationCenter.default.publisher(for: .salesSyncIncoming)) { note in
            if let items = note.userInfo?["items"] as? [SalesItem], let date = note.userInfo?["lastResetDate"] as? Date {
                manager.applyRemoteState(items: items, lastResetDate: date)
            }
        }
        .onAppear { 
            pushState()
            _ = SalesIOSReceiver.shared // Initialize receiver
        }
        .alert("Reset counts?", isPresented: $showingResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { manager.resetCounts(); pushState() }
        } message: { Text("This will set all items to 0 for today.") }
    }
    
    private func pushState() {
        let state = SalesManager.PersistedState(items: manager.items, lastResetDate: manager.lastResetDate)
        SalesSyncCoordinator.shared.send(state: state)
    }
}



