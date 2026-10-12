//
//  WidgetSetupView.swift
//  Rocket Launcher
//
//  Created by Raudel Alejandro on 19-07-2025.
//

import SwiftUI
import WidgetKit
import UIKit

// MARK: - Guide Section
enum SetupGuideTab: String, CaseIterable, Identifiable {
    case quickStart = "Start"
    case widgets = "Widgets"
    case urlSchemes = "Schemes"
    case tipsAndFix = "Tips & Fix"

    var id: String { rawValue }
}

// MARK: - URL Scheme Model
struct URLSchemeItem: Identifiable {
    let id = UUID()
    let name: String
    let scheme: String
    let category: String
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
        URLSchemeItem(name: "Instagram", scheme: "instagram://", category: "Social"),
        URLSchemeItem(name: "Spotify", scheme: "spotify://", category: "Media"),
        URLSchemeItem(name: "YouTube", scheme: "youtube://", category: "Media"),
        URLSchemeItem(name: "X / Twitter", scheme: "twitter://", category: "Social"),
        URLSchemeItem(name: "WhatsApp", scheme: "whatsapp://", category: "Social"),
        URLSchemeItem(name: "TikTok", scheme: "tiktok://", category: "Social"),
        URLSchemeItem(name: "Discord", scheme: "discord://", category: "Social"),
        URLSchemeItem(name: "Telegram", scheme: "tg://", category: "Social"),
        URLSchemeItem(name: "Reddit", scheme: "reddit://", category: "Social"),
        URLSchemeItem(name: "Snapchat", scheme: "snapchat://", category: "Social"),

        // Apple Built-in
        URLSchemeItem(name: "Settings", scheme: "App-Prefs:root=", category: "Apple"),
        URLSchemeItem(name: "Camera", scheme: "camera://", category: "Apple"),
        URLSchemeItem(name: "Photos", scheme: "photos-redirect://", category: "Apple"),
        URLSchemeItem(name: "Maps", scheme: "maps://", category: "Apple"),
        URLSchemeItem(name: "Safari", scheme: "https://", category: "Apple"),
        URLSchemeItem(name: "Mail", scheme: "mailto://", category: "Apple"),
        URLSchemeItem(name: "Phone", scheme: "tel://", category: "Apple"),
        URLSchemeItem(name: "Messages", scheme: "sms://", category: "Apple"),
        URLSchemeItem(name: "FaceTime", scheme: "facetime://", category: "Apple"),
        URLSchemeItem(name: "App Store", scheme: "itms-apps://", category: "Apple"),
        URLSchemeItem(name: "Apple Music", scheme: "music://", category: "Apple"),
        URLSchemeItem(name: "Calendar", scheme: "calshow://", category: "Apple"),
        URLSchemeItem(name: "Reminders", scheme: "x-apple-reminderkit://", category: "Apple"),
        URLSchemeItem(name: "Notes", scheme: "mobilenotes://", category: "Apple"),
        URLSchemeItem(name: "Files", scheme: "shareddocuments://", category: "Apple"),

        // Productivity & Utilities
        URLSchemeItem(name: "Google Chrome", scheme: "googlechrome://", category: "Productivity"),
        URLSchemeItem(name: "Google Search", scheme: "google://", category: "Productivity"),
        URLSchemeItem(name: "Google Maps", scheme: "comgooglemaps://", category: "Productivity"),
        URLSchemeItem(name: "Gmail", scheme: "googlegmail://", category: "Productivity"),
        URLSchemeItem(name: "Notion", scheme: "notion://", category: "Productivity"),
        URLSchemeItem(name: "Slack", scheme: "slack://", category: "Productivity")
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
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Section Switcher
                    Picker("Section", selection: $selectedTab) {
                        ForEach(SetupGuideTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 14)
                    .accessibilityLabel("Guide section")
                    .onChange(of: selectedTab) { _, _ in
                        HapticsHelper.selection()
                    }

                    // Main Scrollable Content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
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
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Setup Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticsHelper.impact(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Done")
                }
            }
            .overlay(alignment: .bottom) {
                if let message = toastMessage {
                    toastView(message)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 24)
                        .zIndex(100)
                }
            }
        }
    }

    // MARK: - Tab 1: Quick Start
    private var quickStartContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Hero Intro Card
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 52, height: 52)
                        Image(systemName: "rocket.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rocket Launcher X")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("5-Step Fast Setup")
                            .font(.subheadline)
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                }

                Text("Turn your Home Screen into an ultra-fast productivity dashboard with instant app launching and smart calendars.")
                    .font(.subheadline)
                    .foregroundColor(Color.white.opacity(0.8))
                    .lineSpacing(2)
            }
            .padding(18)
            .cardSurface()

            // Steps
            VStack(spacing: 12) {
                GuideStepCard(
                    number: 1,
                    title: "Add Widget to Home Screen",
                    subtitle: "Long-press any empty area of your Home Screen until the icons jiggle, then tap the + button in the top-left corner.",
                    color: .blue
                )

                GuideStepCard(
                    number: 2,
                    title: "Search 'Rocket Launcher'",
                    subtitle: "Find Rocket Launcher in the widget gallery. Browse Large Launchers, the Medium Calendar, and the Day Counter.",
                    color: .purple
                )

                GuideStepCard(
                    number: 3,
                    title: "Configure App Slots",
                    subtitle: "Tap 'Add Apps' in the app to set up to 40 launches — 5 widgets with 8 slots each. Enter app names and their URL schemes.",
                    color: .orange
                )

                GuideStepCard(
                    number: 4,
                    title: "Customize Appearance",
                    subtitle: "Tap 'Configure Widget' to pick a custom color or hex code, set text alignment, and toggle app icons — all with a live preview.",
                    color: .green
                )

                GuideStepCard(
                    number: 5,
                    title: "Launch Instantly",
                    subtitle: "Tap an app on your widget and it opens immediately with heavy haptic feedback.",
                    color: .pink
                )
            }
        }
    }

    // MARK: - Tab 2: Widget Gallery
    private var widgetsGalleryContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(icon: "rectangle.stack.fill", color: .blue, title: "AVAILABLE WIDGETS")

            WidgetDetailCard(
                title: "App Launcher Widgets",
                badge: "5 Widgets × 8 Apps",
                sizeText: "Large",
                icon: "app.badge.fill",
                color: .blue,
                description: "Quick access to up to 40 apps across 5 widgets. Supports automatic App Store icon download, custom fonts, text alignment, and custom colors."
            )

            WidgetDetailCard(
                title: "Smart Calendar Widget",
                badge: "Interactive Tap",
                sizeText: "Medium",
                icon: "calendar",
                color: .red,
                description: "A large day number, full weekday date, and day-of-year progress on the left, with a mini monthly grid on the right. Tap action is customizable: open Apple Calendar or any custom URL scheme."
            )

            WidgetDetailCard(
                title: "Day Counter Widget",
                badge: "Daily Overview",
                sizeText: "Small",
                icon: "number.circle.fill",
                color: .orange,
                description: "A clean, glanceable overview of the day number, full formatted date, and cumulative day-of-year progress. Perfect for minimalist setups."
            )

            WidgetDetailCard(
                title: "Mini Calendar Viewer",
                badge: "Full Month",
                sizeText: "Small",
                icon: "calendar.badge.clock",
                color: .purple,
                description: "A compact monthly calendar grid that highlights today in a vibrant accent color and dims weekend columns for high legibility."
            )
        }
    }

    // MARK: - Tab 3: URL Schemes Directory
    private var urlSchemesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Search Bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.white.opacity(0.6))

                TextField("Search apps or schemes", text: $schemeSearchText)
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Search apps or schemes")

                if !schemeSearchText.isEmpty {
                    Button {
                        HapticsHelper.impact(.light)
                        schemeSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )

            // Category Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { cat in
                        let isSelected = selectedCategory == cat
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedCategory = cat
                        } label: {
                            Text(cat)
                                .font(.footnote)
                                .fontWeight(isSelected ? .semibold : .regular)
                                .foregroundColor(isSelected ? .white : Color.white.opacity(0.7))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? Color.blue : Color.white.opacity(0.08))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
            }

            // Schemes List
            if filteredSchemes.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("No schemes match your search or category.")
                )
                .foregroundStyle(Color.white.opacity(0.7))
                .padding(.top, 40)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("\(filteredSchemes.count) SCHEMES FOUND")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.white.opacity(0.6))
                            .tracking(1)
                        Spacer()
                        Text("Tap Test to launch instantly")
                            .font(.caption2)
                            .foregroundColor(Color.white.opacity(0.5))
                    }

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
    }

    // MARK: - Tab 4: Tips & Troubleshooting
    private var tipsAndTroubleshootingContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Pro Tips
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(icon: "star.fill", color: .yellow, title: "PRO TIPS")

                ProTipDetailCard(
                    icon: "eye.slash.fill",
                    color: .purple,
                    title: "Enable 'Reduce Motion' for Blackout Launches",
                    description: "Go to iOS Settings → Accessibility → Motion → turn Reduce Motion ON. This removes the standard launch zoom, creating a seamless blackout transition into your target apps."
                )

                ProTipDetailCard(
                    icon: "gearshape.fill",
                    color: .blue,
                    title: "Settings Are Always One Tap Away",
                    description: "Tap the gear on the main screen to open Settings, where you can export or import your app slots and refetch widget icons."
                )

                ProTipDetailCard(
                    icon: "arrow.down.circle.fill",
                    color: .green,
                    title: "Automatic App Store Icon Fetching",
                    description: "In 'Add Apps', tap 'Fetch All Icons' to query Apple's iTunes Search API and download high-resolution icons for all 40 slots at once."
                )

                ProTipDetailCard(
                    icon: "slider.horizontal.2.square",
                    color: .orange,
                    title: "Calendar Edge Day Testing (Dev Beta)",
                    description: "Inside Settings → DEV BETA, enable 'Calendar Edge Day Testing' to verify calendar highlights at month boundaries across all calendar widgets."
                )
            }

            // Interactive Refresh
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    IconTile(icon: "arrow.clockwise.circle.fill", color: .orange, size: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Force Refresh Widgets")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Reloads every widget timeline immediately.")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.6))
                    }

                    Spacer()
                }

                Button {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    isRefreshingWidgets = true
                    WidgetCenter.shared.reloadAllTimelines()
                    showToast("All widget timelines refreshed! ✅")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        isRefreshingWidgets = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isRefreshingWidgets {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(isRefreshingWidgets ? "Refreshing…" : "Refresh All Widgets Now")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(isRefreshingWidgets)
            }
            .padding(16)
            .cardSurface()

            // Troubleshooting FAQ
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(icon: "questionmark.circle.fill", color: .red, title: "TROUBLESHOOTING FAQ")

                FAQDisclosureCard(
                    problem: "Widgets show blank or not updating after saving?",
                    solution: "Tap 'Refresh All Widgets Now' above. If issues persist, verify that all three project targets share the App Group ID 'group.rocketlauncher'. As a last step, remove and re-add the widget to your Home Screen."
                )

                FAQDisclosureCard(
                    problem: "An app fails to open when tapped on widget?",
                    solution: "Use the 'Test' button in the Schemes tab to verify the scheme syntax. Ensure the target app is installed on your physical device (iOS cannot launch apps that are not installed). Some schemes require specific query parameters."
                )

                FAQDisclosureCard(
                    problem: "Widget shows ghost emoji 👻 or 'App Name'?",
                    solution: "Open 'Add Apps' on the main screen and make sure both the Name and URL Scheme are filled out, then tap Save to write the changes to the shared App Group container."
                )

                FAQDisclosureCard(
                    problem: "Calendar highlight circle showing an unexpected date?",
                    solution: "Check if 'Calendar Edge Day Testing' is enabled under Settings → DEV BETA. This feature intentionally overrides the active day to Saturday or Sunday for boundary verification."
                )
            }
        }
    }

    // MARK: - Toast
    private func toastView(_ message: String) -> some View {
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
        AnalyticsManager.shared.logAppLaunch(scheme: scheme, source: .inApp)
        UIApplication.shared.open(url, options: [:]) { success in
            if success {
                showToast("Successfully launched \(scheme)! 🚀")
            } else {
                showToast("Could not open. App may not be installed.")
            }
        }
    }
}

// MARK: - Shared Components

/// Consistent card surface used across the guide.
private struct CardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
    }
}

private extension View {
    func cardSurface() -> some View {
        modifier(CardSurface())
    }
}

/// Rounded icon tile with tinted fill.
private struct IconTile: View {
    let icon: String
    let color: Color
    var size: CGFloat = 44

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(color.opacity(0.2))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundColor(color)
            )
    }
}

/// Uppercase white section header with accent icon.
private struct SectionHeader: View {
    let icon: String
    let color: Color
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundColor(color)
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .tracking(1)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Guide Step Card
private struct GuideStepCard: View {
    let number: Int
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.2))
                    .frame(width: 38, height: 38)
                Text("\(number)")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(Color.white.opacity(0.75))
                    .lineSpacing(2)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Widget Detail Card
private struct WidgetDetailCard: View {
    let title: String
    let badge: String
    let sizeText: String
    let icon: String
    let color: Color
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                IconTile(icon: icon, color: color)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack(spacing: 6) {
                        Text(sizeText)
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.6))

                        Text("•")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.6))

                        Text(badge)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(color)
                    }
                }

                Spacer(minLength: 0)
            }

            Text(description)
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.75))
                .lineSpacing(2)
        }
        .padding(16)
        .cardSurface()
    }
}

// MARK: - URL Scheme Directory Card
private struct URLSchemeDirectoryCard: View {
    let item: URLSchemeItem
    let onCopy: () -> Void
    let onTestLaunch: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(item.scheme)
                    .font(.caption.monospaced())
                    .foregroundColor(.blue)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button(action: onCopy) {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(.white)
            .accessibilityLabel("Copy \(item.name) scheme")

            Button(action: onTestLaunch) {
                Label("Test", systemImage: "arrow.up.right")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(.blue)
            .accessibilityLabel("Test launch \(item.name)")
        }
        .padding(14)
        .cardSurface()
    }
}

// MARK: - Pro Tip Card
private struct ProTipDetailCard: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconTile(icon: icon, color: color, size: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.7))
                    .lineSpacing(2)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - FAQ Disclosure Card
private struct FAQDisclosureCard: View {
    let problem: String
    let solution: String
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(solution)
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.75))
                .lineSpacing(2)
                .padding(.top, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text(problem)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
            }
        }
        .tint(.white)
        .padding(14)
        .cardSurface()
        .onChange(of: isExpanded) { _, _ in
            HapticsHelper.selection()
        }
    }
}
