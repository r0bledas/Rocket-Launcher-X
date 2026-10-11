//
//  WidgetSetupView.swift
//  Rocket Launcher
//
//  Created by Raudel Alejandro on 19-07-2025.
//

import SwiftUI
import WidgetKit
import UIKit

// MARK: - Guide Segment Tab
enum SetupGuideTab: String, CaseIterable, Identifiable {
    case quickStart = "Quick Start"
    case widgets = "Widgets"
    case urlSchemes = "URL Schemes"
    case tipsAndFix = "Tips & Fix"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .quickStart: return "sparkles"
        case .widgets: return "rectangle.stack.fill"
        case .urlSchemes: return "link.circle.fill"
        case .tipsAndFix: return "wrench.and.screwdriver.fill"
        }
    }
}

// MARK: - URL Scheme Model
struct URLSchemeItem: Identifiable {
    let id = UUID()
    let name: String
    let scheme: String
    let iconName: String
    let category: String
    let color: Color
    let isSystemIcon: Bool
}

// MARK: - Widget Setup View
struct WidgetSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SetupGuideTab = .quickStart
    @State private var schemeSearchText: String = ""
    @State private var selectedCategory: String = "All"
    @State private var toastMessage: String? = nil
    @State private var isRefreshingWidgets: Bool = false
    
    private let categories = ["All", "Social", "Apple", "Productivity", "Media"]
    
    private let urlSchemes: [URLSchemeItem] = [
        // Social
        URLSchemeItem(name: "Instagram", scheme: "instagram://", iconName: "camera.fill", category: "Social", color: .purple, isSystemIcon: true),
        URLSchemeItem(name: "Spotify", scheme: "spotify://", iconName: "music.note", category: "Media", color: .green, isSystemIcon: true),
        URLSchemeItem(name: "YouTube", scheme: "youtube://", iconName: "play.rectangle.fill", category: "Media", color: .red, isSystemIcon: true),
        URLSchemeItem(name: "X / Twitter", scheme: "twitter://", iconName: "bubble.left.and.bubble.right.fill", category: "Social", color: .cyan, isSystemIcon: true),
        URLSchemeItem(name: "WhatsApp", scheme: "whatsapp://", iconName: "phone.circle.fill", category: "Social", color: .green, isSystemIcon: true),
        URLSchemeItem(name: "TikTok", scheme: "tiktok://", iconName: "waveform", category: "Social", color: .pink, isSystemIcon: true),
        URLSchemeItem(name: "Discord", scheme: "discord://", iconName: "person.2.fill", category: "Social", color: .indigo, isSystemIcon: true),
        URLSchemeItem(name: "Telegram", scheme: "tg://", iconName: "paperplane.fill", category: "Social", color: .blue, isSystemIcon: true),
        URLSchemeItem(name: "Reddit", scheme: "reddit://", iconName: "bubble.middle.bottom.fill", category: "Social", color: .orange, isSystemIcon: true),
        URLSchemeItem(name: "Snapchat", scheme: "snapchat://", iconName: "bell.fill", category: "Social", color: .yellow, isSystemIcon: true),
        
        // Apple Built-in
        URLSchemeItem(name: "Settings", scheme: "App-Prefs:root=", iconName: "gear", category: "Apple", color: .gray, isSystemIcon: true),
        URLSchemeItem(name: "Camera", scheme: "camera://", iconName: "camera.aperture", category: "Apple", color: .blue, isSystemIcon: true),
        URLSchemeItem(name: "Photos", scheme: "photos-redirect://", iconName: "photo.on.rectangle.angled", category: "Apple", color: .red, isSystemIcon: true),
        URLSchemeItem(name: "Maps", scheme: "maps://", iconName: "map.fill", category: "Apple", color: .green, isSystemIcon: true),
        URLSchemeItem(name: "Safari", scheme: "https://", iconName: "safari.fill", category: "Apple", color: .blue, isSystemIcon: true),
        URLSchemeItem(name: "Mail", scheme: "mailto://", iconName: "envelope.fill", category: "Apple", color: .cyan, isSystemIcon: true),
        URLSchemeItem(name: "Phone", scheme: "tel://", iconName: "phone.fill", category: "Apple", color: .green, isSystemIcon: true),
        URLSchemeItem(name: "Messages", scheme: "sms://", iconName: "message.fill", category: "Apple", color: .green, isSystemIcon: true),
        URLSchemeItem(name: "FaceTime", scheme: "facetime://", iconName: "video.fill", category: "Apple", color: .green, isSystemIcon: true),
        URLSchemeItem(name: "App Store", scheme: "itms-apps://", iconName: "bag.fill", category: "Apple", color: .blue, isSystemIcon: true),
        URLSchemeItem(name: "Apple Music", scheme: "music://", iconName: "music.quarternote.3", category: "Apple", color: .red, isSystemIcon: true),
        URLSchemeItem(name: "Calendar", scheme: "calshow://", iconName: "calendar", category: "Apple", color: .red, isSystemIcon: true),
        URLSchemeItem(name: "Reminders", scheme: "x-apple-reminderkit://", iconName: "list.bullet", category: "Apple", color: .orange, isSystemIcon: true),
        URLSchemeItem(name: "Notes", scheme: "mobilenotes://", iconName: "note.text", category: "Apple", color: .yellow, isSystemIcon: true),
        URLSchemeItem(name: "Files", scheme: "shareddocuments://", iconName: "folder.fill", category: "Apple", color: .blue, isSystemIcon: true),
        
        // Productivity & Utilities
        URLSchemeItem(name: "Google Chrome", scheme: "googlechrome://", iconName: "globe", category: "Productivity", color: .blue, isSystemIcon: true),
        URLSchemeItem(name: "Google Search", scheme: "google://", iconName: "magnifyingglass", category: "Productivity", color: .blue, isSystemIcon: true),
        URLSchemeItem(name: "Google Maps", scheme: "comgooglemaps://", iconName: "location.fill", category: "Productivity", color: .red, isSystemIcon: true),
        URLSchemeItem(name: "Gmail", scheme: "googlegmail://", iconName: "tray.fill", category: "Productivity", color: .red, isSystemIcon: true),
        URLSchemeItem(name: "Notion", scheme: "notion://", iconName: "doc.richtext.fill", category: "Productivity", color: .gray, isSystemIcon: true),
        URLSchemeItem(name: "Slack", scheme: "slack://", iconName: "number", category: "Productivity", color: .purple, isSystemIcon: true)
    ]
    
    var filteredSchemes: [URLSchemeItem] {
        urlSchemes.filter { item in
            let matchesCategory = (selectedCategory == "All") || (item.category == selectedCategory)
            let matchesSearch = schemeSearchText.isEmpty ||
                item.name.localizedCaseInsensitiveContains(schemeSearchText) ||
                item.scheme.localizedCaseInsensitiveContains(schemeSearchText)
            return matchesCategory && matchesSearch
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Segmented Bar
                    segmentedHeader
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 16)
                    
                    // Main Scrollable Content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            switch selectedTab {
                            case .quickStart:
                                quickStartContent
                            case .widgets:
                                widgetsGalleryContent
                            case .urlSchemes:
                                urlSchemesContent
                            case .tipsAndFix:
                                tipsAndTroubleshootingContent
                            }
                            
                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    }
                }
                
                // Toast notification overlay
                if let message = toastMessage {
                    VStack {
                        Spacer()
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(message)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color(hex: "#1E1E1E"))
                                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        )
                        .shadow(color: .black.opacity(0.4), radius: 10, y: 5)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 24)
                    }
                    .zIndex(100)
                }
            }
            .navigationTitle("Setup Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    // MARK: - Segmented Header
    private var segmentedHeader: some View {
        HStack(spacing: 6) {
            ForEach(SetupGuideTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 13, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                    }
                    .foregroundColor(isSelected ? .white : .gray)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isSelected ? Color.blue : Color.gray.opacity(0.15))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Tab 1: Quick Start
    private var quickStartContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Hero Intro Card
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 48, height: 48)
                        Image(systemName: "rocket.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rocket Launcher X")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("5-Step Fast Setup")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Text("Transform your Home Screen into an ultra-fast productivity dashboard with instant app launching and smart calendars.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(2)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.gray.opacity(0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            
            // Steps
            VStack(spacing: 12) {
                GuideStepCard(
                    number: 1,
                    icon: "hand.tap.fill",
                    title: "Add Widget to Home Screen",
                    subtitle: "Long-press any empty area on your Home Screen until icons jiggle, then tap the '+' button in the top left corner.",
                    color: .blue
                )
                
                GuideStepCard(
                    number: 2,
                    icon: "magnifyingglass",
                    title: "Search 'Rocket Launcher'",
                    subtitle: "Search for Rocket Launcher in the widget gallery. Browse through Large Launchers, Medium Calendar, and Day Counter.",
                    color: .purple
                )
                
                GuideStepCard(
                    number: 3,
                    icon: "plus.circle.fill",
                    title: "Configure App Slots",
                    subtitle: "Tap 'Add Apps' in the Rocket Launcher app. You have 5 large widgets with 8 slots each (up to 40 total apps). Enter app names and custom URL schemes.",
                    color: .orange
                )
                
                GuideStepCard(
                    number: 4,
                    icon: "paintpalette.fill",
                    title: "Customize Static Color & Font",
                    subtitle: "Tap 'Configure Widget' to pick a true static solid background (Pitch Black, Space Gray, Slate, or custom Hex), alignment, and toggle icons with live preview.",
                    color: .green
                )
                
                GuideStepCard(
                    number: 5,
                    icon: "bolt.fill",
                    title: "Instant Launch with Haptics",
                    subtitle: "Tap any app name directly from your Home Screen widget. Rocket Launcher launches the destination app instantly with heavy haptic feedback.",
                    color: .pink
                )
            }
        }
    }
    
    // MARK: - Tab 2: Widget Gallery
    private var widgetsGalleryContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("AVAILABLE WIDGETS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.gray)
                .tracking(1)
            
            // 1. App Launchers
            WidgetDetailCard(
                title: "App Launcher Widgets",
                badge: "5 Widgets × 8 Apps",
                sizeText: "Large (System Large)",
                icon: "app.badge.fill",
                color: .blue,
                description: "Quick access to up to 40 apps organized across 5 dedicated widgets (Widget 1: Apps 0-7, Widget 2: Apps 8-15, Widget 3: Apps 16-23, Widget 4: Apps 24-31, Widget 5: Apps 32-39). Supports automatic App Store icon download, custom fonts, text alignment, and flat static color backgrounds."
            )
            
            // 2. Calendar Widget
            WidgetDetailCard(
                title: "Smart Calendar Widget",
                badge: "Interactive Tap",
                sizeText: "Medium (System Medium)",
                icon: "calendar",
                color: .red,
                description: "Left side features a large day number, full weekday date, and day-of-year progress (e.g. 277/365). Right side shows a mini monthly grid with your current day highlighted. Tap action is customizable: opens Apple Calendar (calshow://) or any custom URL scheme."
            )
            
            // 3. Day Counter Widget
            WidgetDetailCard(
                title: "Day Counter Widget",
                badge: "Daily Overview",
                sizeText: "Small (System Small)",
                icon: "number.circle.fill",
                color: .orange,
                description: "Clean, glanceable overview focused on the day number, full formatted date, and cumulative day-of-year progress. Perfect for minimalist setups."
            )
            
            // 4. Calendar Viewer Widget
            WidgetDetailCard(
                title: "Mini Calendar Viewer",
                badge: "Full Month",
                sizeText: "Small (System Small)",
                icon: "calendar.badge.clock",
                color: .purple,
                description: "Compact monthly calendar grid highlighting today's date in vibrant accent color with weekend columns dimmed for high legibility."
            )
        }
    }
    
    // MARK: - Tab 3: URL Schemes Directory
    private var urlSchemesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Search Bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search apps or schemes (e.g. Spotify, Settings)", text: $schemeSearchText)
                    .foregroundColor(.white)
                    .font(.subheadline)
                
                if !schemeSearchText.isEmpty {
                    Button(action: { schemeSearchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color.gray.opacity(0.18))
            .cornerRadius(12)
            
            // Category Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { cat in
                        let isSelected = selectedCategory == cat
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedCategory = cat
                        }) {
                            Text(cat)
                                .font(.caption)
                                .fontWeight(isSelected ? .bold : .medium)
                                .foregroundColor(isSelected ? .white : .gray)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.15))
                                )
                        }
                    }
                }
            }
            
            // Schemes Count
            HStack {
                Text("\(filteredSchemes.count) SCHEMES FOUND")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .tracking(1)
                Spacer()
                Text("Tap Test to test launch instantly")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(.top, 4)
            
            // Schemes List
            VStack(spacing: 10) {
                ForEach(filteredSchemes) { item in
                    URLSchemeDirectoryCard(
                        item: item,
                        onCopy: {
                            UIPasteboard.general.string = item.scheme
                            showToast("Copied '\(item.scheme)' to clipboard!")
                        },
                        onTestLaunch: {
                            testLaunch(scheme: item.scheme)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Tab 4: Tips & Troubleshooting
    private var tipsAndTroubleshootingContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Pro Tips Section
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("PRO TIPS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .tracking(1)
                }
                
                ProTipDetailCard(
                    icon: "eye.slash.fill",
                    color: .purple,
                    title: "Enable 'Reduce Motion' for Blackout Launches",
                    description: "Go to iOS Settings → Accessibility → Motion → turn Reduce Motion ON. This eliminates the standard app launch zoom animation, creating a seamless, instant blackout transition directly into your target apps."
                )
                
                ProTipDetailCard(
                    icon: "iphone.radiowaves.left.and.right",
                    color: .blue,
                    title: "Shake Device to Reveal Settings",
                    description: "Rocket Launcher includes hidden settings protected by CoreMotion shake detection. Give your phone a quick shake on the main screen to reveal the floating Settings gear icon, or enable 'Always Show Settings Button' inside Settings."
                )
                
                ProTipDetailCard(
                    icon: "arrow.down.circle.fill",
                    color: .green,
                    title: "Automatic App Store Icon Fetching",
                    description: "When editing app names in 'Add Apps', tap 'Fetch All Icons' to automatically query Apple's iTunes Search API and download high-resolution icons for all 40 slots simultaneously."
                )
                
                ProTipDetailCard(
                    icon: "slider.horizontal.2.square",
                    color: .orange,
                    title: "Calendar Edge Day Testing (Dev Beta)",
                    description: "Inside Settings → DEV BETA, enable 'Calendar Edge Day Testing' to test calendar layout highlights at month boundaries (Sundays and Saturdays) across all calendar widgets."
                )
            }
            
            // Interactive Refresh Button Card
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Force Refresh Widgets")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Immediately reloads all widget timelines via WidgetCenter")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                
                Button(action: {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    isRefreshingWidgets = true
                    WidgetCenter.shared.reloadAllTimelines()
                    showToast("All widget timelines refreshed! ✅")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        isRefreshingWidgets = false
                    }
                }) {
                    HStack {
                        if isRefreshingWidgets {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(isRefreshingWidgets ? "Refreshing..." : "Refresh All Widgets Now")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .cornerRadius(12)
                }
            }
            .padding(16)
            .background(Color.gray.opacity(0.14))
            .cornerRadius(16)
            
            // Troubleshooting FAQ Section
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(.red)
                    Text("TROUBLESHOOTING FAQ")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .tracking(1)
                }
                
                TroubleshootingFAQCard(
                    problem: "Widgets show blank or not updating after saving?",
                    solution: "Tap 'Refresh All Widgets Now' above. If issues persist, verify that all three project targets share the App Group ID 'group.rocketlauncher'. As a last step, remove and re-add the widget to your Home Screen."
                )
                
                TroubleshootingFAQCard(
                    problem: "An app fails to open when tapped on widget?",
                    solution: "Use the 'Test' button in the URL Schemes tab to verify the scheme syntax. Ensure the target app is installed on your physical device (iOS cannot launch apps that are not installed). Some schemes require specific query parameters (e.g. 'instagram://' instead of 'instagram')."
                )
                
                TroubleshootingFAQCard(
                    problem: "Widget shows ghost emoji 👻 or 'App Name'?",
                    solution: "Open 'Add Apps' on the main screen and make sure both the Name and URL Scheme are filled out, then tap Save to write the changes to the shared App Group container."
                )
                
                TroubleshootingFAQCard(
                    problem: "Calendar highlight circle showing an unexpected date?",
                    solution: "Check if 'Calendar Edge Day Testing' is enabled under Settings → DEV BETA. This feature intentionally overrides the active day to Saturday or Sunday for boundary verification."
                )
            }
        }
    }
    
    // MARK: - Actions
    private func showToast(_ message: String) {
        toastMessage = message
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                if toastMessage == message {
                    toastMessage = nil
                }
            }
        }
    }
    
    private func testLaunch(scheme: String) {
        guard let url = URL(string: scheme) else {
            showToast("Invalid URL scheme syntax")
            return
        }
        
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        UIApplication.shared.open(url, options: [:]) { success in
            if success {
                showToast("Successfully launched \(scheme)! 🚀")
            } else {
                showToast("Could not open. App may not be installed.")
            }
        }
    }
}

// MARK: - Guide Step Card
struct GuideStepCard: View {
    let number: Int
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 38, height: 38)
                
                Text("\(number)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineSpacing(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.gray.opacity(0.12))
        )
    }
}

// MARK: - Widget Detail Card
struct WidgetDetailCard: View {
    let title: String
    let badge: String
    let sizeText: String
    let icon: String
    let color: Color
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        Text(sizeText)
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Text(badge)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(color)
                    }
                }
                
                Spacer()
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.75))
                .lineSpacing(2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.gray.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - URL Scheme Card
struct URLSchemeDirectoryCard: View {
    let item: URLSchemeItem
    let onCopy: () -> Void
    let onTestLaunch: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.color.opacity(0.2))
                    .frame(width: 38, height: 38)
                
                Image(systemName: item.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(item.color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(item.scheme)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            // Copy button
            Button(action: onCopy) {
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.doc")
                    Text("Copy")
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.25))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Test button
            Button(action: onTestLaunch) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                    Text("Test")
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.blue)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.gray.opacity(0.12))
        )
    }
}

// MARK: - Pro Tip Card
struct ProTipDetailCard: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineSpacing(2)
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color.gray.opacity(0.12))
        .cornerRadius(14)
    }
}

// MARK: - Troubleshooting FAQ Card
struct TroubleshootingFAQCard: View {
    let problem: String
    let solution: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text(problem)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            Text(solution)
                .font(.caption)
                .foregroundColor(.gray)
                .lineSpacing(2)
        }
        .padding(14)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(14)
    }
}