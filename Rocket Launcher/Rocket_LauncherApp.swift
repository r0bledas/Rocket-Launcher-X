//
//  Rocket_LauncherApp.swift
//  Rocket Launcher
//
//  Created by Raudel Alejandro on 19-07-2025.
//

import SwiftUI
import UIKit

@main
struct Rocket_LauncherApp: App {
    @StateObject private var urlHandler = URLHandler()
    @StateObject private var storeManager = StoreManager()
    @State private var showLaunchFailureAlert = false
    @State private var failedScheme: String? = nil
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(urlHandler)
                .environmentObject(storeManager)
                .onOpenURL { url in
                    let didLaunch = urlHandler.handleURL(url) { failedScheme in
                        self.failedScheme = failedScheme
                        self.showLaunchFailureAlert = true
                        print("❌ Failed to launch app: \(failedScheme)")
                    }
                    if didLaunch {
                        print("✅ URL scheme handled: \(url.absoluteString)")
                    } else {
                        print("⚠️ Unhandled URL: \(url.absoluteString)")
                    }
                }
                .alert(isPresented: $showLaunchFailureAlert) {
                    Alert(
                        title: Text("Failed to Launch App"),
                        message: Text("Could not open the app for scheme: \(failedScheme ?? "")"),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .statusBarHidden(true)
                .ignoresSafeArea(.all, edges: .all)
        }
    }
}

class URLHandler: ObservableObject {
    @Published var targetAppScheme: String?
    
    // Centralized haptic feedback for all app launches
    static func playLaunchHaptic() {
        print("🔊 Playing single hard haptic...")
        
        DispatchQueue.main.async {
            let hapticGenerator = UIImpactFeedbackGenerator(style: .heavy)
            hapticGenerator.prepare()
            hapticGenerator.impactOccurred()
            print("✅ Single hard haptic played")
        }
    }
    
    // Returns true if handled, false otherwise. Calls onFailure if launch fails.
    func handleURL(_ url: URL, onFailure: ((String) -> Void)? = nil) -> Bool {
        print("🚀 handleURL called with: \(url)")
        print("🔍 URL scheme: \(url.scheme ?? "nil")")
        
        // Handle custom URL schemes like rocketlauncher://launch?scheme=app-scheme://
        if url.scheme == "rocketlauncher" {
            print("✅ Rocket launcher scheme detected")
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems {
                print("📋 Query items: \(queryItems)")
                
                if let scheme = queryItems.first(where: { $0.name == "scheme" })?.value {
                    print("🎯 Launching with scheme param: \(scheme)")
                    let appName = queryItems.first(where: { $0.name == "name" })?.value
                    let widget = queryItems.first(where: { $0.name == "widget" })?.value.flatMap(Int.init)
                    let slot = queryItems.first(where: { $0.name == "slot" })?.value.flatMap(Int.init)
                    // Launch the target app immediately
                    launchApp(withScheme: scheme, appName: appName, widget: widget, slot: slot, onFailure: onFailure)
                    return true
                }
                // Legacy: support ?app=...
                if let appScheme = queryItems.first(where: { $0.name == "app" })?.value {
                    print("🎯 Launching with app param: \(appScheme)")
                    launchApp(withScheme: appScheme, onFailure: onFailure)
                    return true
                }
            }
        } else {
            print("❌ Not a rocket launcher scheme")
        }
        return false
    }
    
    private func launchApp(withScheme scheme: String, appName: String? = nil, widget: Int? = nil, slot: Int? = nil, onFailure: ((String) -> Void)? = nil) {
        print("launchApp called with scheme: \(scheme)")
        guard let url = URL(string: scheme) else { print("Invalid URL from scheme"); onFailure?(scheme); return }
        
        // Single hard haptic feedback
        print("🔊 Playing single hard haptic...")
        URLHandler.playLaunchHaptic()
        
        // Pseudonymous, opt-in usage analytics: app name, full scheme, widget/slot
        // and local hour. Sent only when the user has enabled it.
        AnalyticsManager.shared.logAppLaunch(
            scheme: scheme,
            source: .widget,
            appName: appName,
            widget: widget,
            slot: slot
        )
        
        // Note: The scheme must be listed in LSApplicationQueriesSchemes in Info.plist
        UIApplication.shared.open(url, options: [:], completionHandler: { success in
            print("UIApplication.shared.open success: \(success)")
            if !success {
                onFailure?(scheme)
            } else {
                // Add notification haptic for successful launch
                let notificationGenerator = UINotificationFeedbackGenerator()
                notificationGenerator.notificationOccurred(.success)
                // App stays open after successful launch
            }
        })
    }
}
