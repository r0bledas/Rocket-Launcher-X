//
//  AppCatalog.swift
//  Rocket Launcher
//
//  Directory of apps and their URL schemes / universal links.
//
//  The app fetches a maintained, community list from GitHub at runtime and
//  falls back to the bundled list below when offline. Results are cached to
//  disk so subsequent launches are instant.
//
//  Remote source: https://github.com/sxp-studio/app-list-catalog (MIT)
//

import SwiftUI

struct CatalogApp: Identifiable, Hashable, Codable {
    let name: String
    let scheme: String
    let category: String

    var id: String { scheme }
}

enum AppCatalog {
    /// Remote list (fetchable JSON).
    static let remoteURL = URL(string: "https://raw.githubusercontent.com/sxp-studio/app-list-catalog/main/apps.json")!

    /// Offline fallback used before the first successful fetch.
    static let bundled: [CatalogApp] = [
        // MARK: Apple
        CatalogApp(name: "Settings", scheme: "App-Prefs:root=", category: "Apple"),
        CatalogApp(name: "App Store", scheme: "itms-apps://", category: "Apple"),
        CatalogApp(name: "Camera", scheme: "camera://", category: "Apple"),
        CatalogApp(name: "Photos", scheme: "photos-redirect://", category: "Apple"),
        CatalogApp(name: "Maps", scheme: "maps://", category: "Apple"),
        CatalogApp(name: "Safari", scheme: "https://", category: "Apple"),
        CatalogApp(name: "Mail", scheme: "mailto://", category: "Apple"),
        CatalogApp(name: "Phone", scheme: "tel://", category: "Apple"),
        CatalogApp(name: "Messages", scheme: "sms://", category: "Apple"),
        CatalogApp(name: "FaceTime", scheme: "facetime://", category: "Apple"),
        CatalogApp(name: "Apple Music", scheme: "music://", category: "Apple"),
        CatalogApp(name: "Calendar", scheme: "calshow://", category: "Apple"),
        CatalogApp(name: "Reminders", scheme: "x-apple-reminderkit://", category: "Apple"),
        CatalogApp(name: "Notes", scheme: "mobilenotes://", category: "Apple"),
        CatalogApp(name: "Files", scheme: "shareddocuments://", category: "Apple"),
        CatalogApp(name: "Podcasts", scheme: "podcasts://", category: "Apple"),
        CatalogApp(name: "Books", scheme: "ibooks://", category: "Apple"),
        CatalogApp(name: "Apple News", scheme: "applenews://", category: "Apple"),
        CatalogApp(name: "Shortcuts", scheme: "shortcuts://", category: "Apple"),
        CatalogApp(name: "Clock", scheme: "clock://", category: "Apple"),

        // MARK: Social
        CatalogApp(name: "Instagram", scheme: "instagram://", category: "Social"),
        CatalogApp(name: "Facebook", scheme: "fb://", category: "Social"),
        CatalogApp(name: "Messenger", scheme: "fb-messenger://", category: "Social"),
        CatalogApp(name: "WhatsApp", scheme: "whatsapp://", category: "Social"),
        CatalogApp(name: "Telegram", scheme: "tg://", category: "Social"),
        CatalogApp(name: "X / Twitter", scheme: "twitter://", category: "Social"),
        CatalogApp(name: "Snapchat", scheme: "snapchat://", category: "Social"),
        CatalogApp(name: "TikTok", scheme: "tiktok://", category: "Social"),
        CatalogApp(name: "Discord", scheme: "discord://", category: "Social"),
        CatalogApp(name: "LinkedIn", scheme: "linkedin://", category: "Social"),
        CatalogApp(name: "Pinterest", scheme: "pinterest://", category: "Social"),
        CatalogApp(name: "Tumblr", scheme: "tumblr://", category: "Social"),
        CatalogApp(name: "Reddit", scheme: "reddit://", category: "Social"),
        CatalogApp(name: "Viber", scheme: "viber://", category: "Social"),
        CatalogApp(name: "WeChat", scheme: "weixin://", category: "Social"),
        CatalogApp(name: "Line", scheme: "line://", category: "Social"),

        // MARK: Media
        CatalogApp(name: "Spotify", scheme: "spotify://", category: "Media"),
        CatalogApp(name: "YouTube", scheme: "youtube://", category: "Media"),
        CatalogApp(name: "Netflix", scheme: "nflx://", category: "Media"),
        CatalogApp(name: "Hulu", scheme: "hulu://", category: "Media"),
        CatalogApp(name: "Disney+", scheme: "disneyplus://", category: "Media"),
        CatalogApp(name: "Twitch", scheme: "twitch://", category: "Media"),
        CatalogApp(name: "SoundCloud", scheme: "soundcloud://", category: "Media"),
        CatalogApp(name: "Shazam", scheme: "shazam://", category: "Media"),
        CatalogApp(name: "Deezer", scheme: "deezer://", category: "Media"),
        CatalogApp(name: "VLC", scheme: "vlc://", category: "Media"),
        CatalogApp(name: "Audible", scheme: "audible://", category: "Media"),

        // MARK: Productivity & Utilities
        CatalogApp(name: "Google Chrome", scheme: "googlechrome://", category: "Productivity"),
        CatalogApp(name: "Google Search", scheme: "google://", category: "Productivity"),
        CatalogApp(name: "Google Maps", scheme: "comgooglemaps://", category: "Productivity"),
        CatalogApp(name: "Gmail", scheme: "googlegmail://", category: "Productivity"),
        CatalogApp(name: "Google Drive", scheme: "googledrive://", category: "Productivity"),
        CatalogApp(name: "Notion", scheme: "notion://", category: "Productivity"),
        CatalogApp(name: "Slack", scheme: "slack://", category: "Productivity"),
        CatalogApp(name: "Evernote", scheme: "evernote://", category: "Productivity"),
        CatalogApp(name: "OneNote", scheme: "onenote://", category: "Productivity"),
        CatalogApp(name: "Trello", scheme: "trello://", category: "Productivity"),
        CatalogApp(name: "OneDrive", scheme: "ms-onedrive://", category: "Productivity"),
        CatalogApp(name: "Zoom", scheme: "zoomus://", category: "Productivity"),
        CatalogApp(name: "Microsoft Teams", scheme: "msteams://", category: "Productivity"),
        CatalogApp(name: "Outlook", scheme: "ms-outlook://", category: "Productivity"),
        CatalogApp(name: "Things", scheme: "things://", category: "Productivity"),
        CatalogApp(name: "Todoist", scheme: "todoist://", category: "Productivity"),
        CatalogApp(name: "Bear", scheme: "bear://", category: "Productivity"),
        CatalogApp(name: "Notability", scheme: "notability://", category: "Productivity"),
        CatalogApp(name: "GoodNotes", scheme: "goodnotes5://", category: "Productivity"),
        CatalogApp(name: "Fantastical", scheme: "fantastical2://", category: "Productivity"),
        CatalogApp(name: "Spark", scheme: "readdle-spark://", category: "Productivity"),
        CatalogApp(name: "Firefox", scheme: "firefox://", category: "Productivity"),
        CatalogApp(name: "Brave", scheme: "brave://", category: "Productivity"),
        CatalogApp(name: "1Password", scheme: "onepassword://", category: "Productivity"),
        CatalogApp(name: "Bitwarden", scheme: "bitwarden://", category: "Productivity"),
        CatalogApp(name: "LastPass", scheme: "lastpass://", category: "Productivity"),

        // MARK: Navigation & Transport
        CatalogApp(name: "Waze", scheme: "waze://", category: "Navigation"),
        CatalogApp(name: "Uber", scheme: "uber://", category: "Navigation"),
        CatalogApp(name: "Lyft", scheme: "lyft://", category: "Navigation"),
        CatalogApp(name: "Citymapper", scheme: "citymapper://", category: "Navigation"),

        // MARK: Shopping & Finance
        CatalogApp(name: "Amazon", scheme: "amzn://", category: "Shopping"),
        CatalogApp(name: "eBay", scheme: "ebay://", category: "Shopping"),
        CatalogApp(name: "PayPal", scheme: "paypal://", category: "Finance"),
        CatalogApp(name: "Venmo", scheme: "venmo://", category: "Finance"),
        CatalogApp(name: "Cash App", scheme: "squarecash://", category: "Finance"),

        // MARK: News & Reading
        CatalogApp(name: "Flipboard", scheme: "flipboard://", category: "News"),
        CatalogApp(name: "Pocket", scheme: "pocket://", category: "News"),
        CatalogApp(name: "Feedly", scheme: "feedly://", category: "News"),

        // MARK: Games
        CatalogApp(name: "Steam", scheme: "steam://", category: "Games")
    ]

    /// A flat search over name and scheme, case-insensitive.
    static func search(_ query: String, in apps: [CatalogApp]) -> [CatalogApp] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return apps }
        return apps.filter {
            $0.name.localizedCaseInsensitiveContains(q) ||
            $0.scheme.localizedCaseInsensitiveContains(q)
        }
    }

    // MARK: - Remote loading

    private struct RemoteApp: Decodable {
        let name: String
        let url: String
        let isFirstParty: Bool?
    }

    private static var cacheFileURL: URL? {
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = caches.appendingPathComponent("AppCatalog", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("apps.json")
    }

    /// Fetches the remote catalog, falling back to a fresh disk cache and then nil.
    static func fetchRemote() async -> [CatalogApp]? {
        if let cached = cachedAppsIfFresh() {
            return cached
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: remoteURL)
            if let url = cacheFileURL {
                try? data.write(to: url)
            }
            return decodeRemote(data) ?? bundled
        } catch {
            return nil
        }
    }

    private static func cachedAppsIfFresh() -> [CatalogApp]? {
        guard let url = cacheFileURL,
              let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let modified = attrs[.modificationDate] as? Date,
              Date().timeIntervalSince(modified) < 7 * 24 * 3600,
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return decodeRemote(data)
    }

    private static func decodeRemote(_ data: Data) -> [CatalogApp]? {
        guard let remote = try? JSONDecoder().decode([RemoteApp].self, from: data), !remote.isEmpty else {
            return nil
        }
        return remote
            .filter { !$0.url.isEmpty && !$0.url.hasPrefix("shortcuts://") }
            .map { CatalogApp(name: $0.name, scheme: $0.url, category: ($0.isFirstParty == true ? "Apple" : "Apps")) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

/// Observable holder for the catalog used by the app picker.
final class AppCatalogStore: ObservableObject {
    @Published var apps: [CatalogApp] = AppCatalog.bundled
    @Published var isLoading = false

    private var didAttempt = false

    @MainActor
    func loadRemoteIfNeeded() async {
        guard !didAttempt else { return }
        didAttempt = true
        isLoading = true
        if let remote = await AppCatalog.fetchRemote() {
            apps = remote
        }
        isLoading = false
    }
}
