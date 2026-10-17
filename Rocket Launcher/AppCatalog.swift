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
        CatalogApp(name: "Passwords", scheme: "apple-otpauth-migration://", category: "Apple"),

        // MARK: Social
        CatalogApp(name: "Instagram", scheme: "instagram://", category: "Social"),
        CatalogApp(name: "Facebook", scheme: "fb://", category: "Social"),
        CatalogApp(name: "Facebook Marketplace", scheme: "https://m.facebook.com/marketplace/", category: "Social"),
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
        CatalogApp(name: "Amperfy", scheme: "amperfy://", category: "Media"),

        // MARK: Productivity & Utilities
        CatalogApp(name: "Google Chrome", scheme: "googlechrome://", category: "Productivity"),
        CatalogApp(name: "Google", scheme: "google://", category: "Productivity"),
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
        CatalogApp(name: "ChatGPT", scheme: "chatgpt://", category: "Productivity"),
        CatalogApp(name: "Claude", scheme: "claude://", category: "Productivity"),
        CatalogApp(name: "DeepSeek", scheme: "deepseek://", category: "Productivity"),
        CatalogApp(name: "Gemini", scheme: "googlegemini://", category: "Productivity"),
        CatalogApp(name: "CamScanner", scheme: "camscanner://", category: "Productivity"),

        // MARK: Utilities
        CatalogApp(name: "Mi Telcel", scheme: "mitelcel://", category: "Utilities"),
        CatalogApp(name: "SmartFlow", scheme: "smartflow://", category: "Utilities"),

        // MARK: Navigation & Transport
        CatalogApp(name: "Waze", scheme: "waze://", category: "Navigation"),
        CatalogApp(name: "Uber", scheme: "uber://", category: "Navigation"),
        CatalogApp(name: "Lyft", scheme: "lyft://", category: "Navigation"),
        CatalogApp(name: "Citymapper", scheme: "citymapper://", category: "Navigation"),

        // MARK: Shopping & Finance
        CatalogApp(name: "Amazon", scheme: "amzn://", category: "Shopping"),
        CatalogApp(name: "Amazon MX", scheme: "https://www.amazon.com.mx/", category: "Shopping"),
        CatalogApp(name: "Amazon US", scheme: "https://www.amazon.com/", category: "Shopping"),
        CatalogApp(name: "Mercado Libre", scheme: "https://www.mercadolibre.com.mx/", category: "Shopping"),
        CatalogApp(name: "eBay", scheme: "ebay://", category: "Shopping"),
        CatalogApp(name: "PayPal", scheme: "paypal://", category: "Finance"),
        CatalogApp(name: "Venmo", scheme: "venmo://", category: "Finance"),
        CatalogApp(name: "Cash App", scheme: "squarecash://", category: "Finance"),
        CatalogApp(name: "BBVA", scheme: "bbvamovilmx://", category: "Finance"),

        // MARK: News & Reading
        CatalogApp(name: "Flipboard", scheme: "flipboard://", category: "News"),
        CatalogApp(name: "Pocket", scheme: "pocket://", category: "News"),
        CatalogApp(name: "Feedly", scheme: "feedly://", category: "News"),

        // MARK: Games
        CatalogApp(name: "Steam", scheme: "steam://", category: "Games"),
        CatalogApp(name: "Clash Royale", scheme: "clashroyale://", category: "Games"),
        CatalogApp(name: "Brawl Stars", scheme: "brawlstars://", category: "Games"),
        CatalogApp(name: "Minecraft", scheme: "minecraft://", category: "Games"),
        CatalogApp(name: "Chess", scheme: "fb2427617054://", category: "Games")
    ]

    /// Relevance-ranked search over name and scheme.
    ///
    /// Ranking (best first): exact name match, exact scheme match, name prefix,
    /// scheme prefix, name contains, scheme contains. Ties break on shorter name,
    /// then alphabetically.
    static func search(_ query: String, in apps: [CatalogApp]) -> [CatalogApp] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else {
            return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }

        func rank(_ app: CatalogApp) -> Int? {
            let name = app.name.lowercased()
            let scheme = app.scheme.lowercased()
            if name == q { return 0 }
            if scheme == q || scheme == "\(q)://" { return 1 }
            if name.hasPrefix(q) { return 2 }
            if scheme.hasPrefix(q) { return 3 }
            if name.contains(q) { return 4 }
            if scheme.contains(q) { return 5 }
            return nil
        }

        return apps
            .compactMap { app -> (app: CatalogApp, rank: Int, length: Int)? in
                guard let r = rank(app) else { return nil }
                return (app, r, app.name.count)
            }
            .sorted { a, b in
                if a.rank != b.rank { return a.rank < b.rank }
                if a.length != b.length { return a.length < b.length }
                return a.app.name.localizedCaseInsensitiveCompare(b.app.name) == .orderedAscending
            }
            .map { $0.app }
    }

    /// Curated, non-alphabetical order for the "Suggested" section: popular
    /// social/messaging first, then media, AI/productivity, Apple preinstalled
    /// utilities, shopping/finance, navigation, games and news. Anything not
    /// listed falls through to alphabetical order.
    static let suggestedPriority: [String] = [
        // Social & messaging
        "instagram", "whatsapp", "tiktok", "facebook", "messenger", "telegram",
        "snapchat", "discord", "x / twitter", "reddit", "linkedin", "pinterest",
        "viber", "wechat", "line", "tumblr",
        // Media
        "youtube", "spotify", "netflix", "apple music", "twitch", "soundcloud",
        "hulu", "disney+", "deezer", "shazam", "audible", "vlc", "amperfy",
        "podcasts", "books",
        // AI & productivity
        "chatgpt", "claude", "gemini", "deepseek", "google", "google maps",
        "gmail", "google drive", "google chrome", "notion", "slack", "zoom",
        "microsoft teams", "outlook", "trello", "onenote", "evernote", "things",
        "todoist", "bear", "notability", "goodnotes", "fantastical", "spark",
        "firefox", "brave", "camscanner", "1password", "bitwarden", "lastpass",
        // Apple preinstalled / utilities
        "settings", "camera", "photos", "files", "calendar", "clock",
        "reminders", "notes", "safari", "mail", "phone", "messages", "facetime",
        "maps", "app store", "shortcuts", "passwords",
        // Shopping & finance
        "amazon", "amazon mx", "amazon us", "mercado libre", "ebay", "paypal",
        "venmo", "cash app", "bbva",
        // Navigation
        "waze", "uber", "lyft", "citymapper",
        // Games
        "steam", "clash royale", "brawl stars", "minecraft", "chess",
        // News & reading
        "flipboard", "pocket", "feedly"
    ]

    /// Orders apps by `suggestedPriority`, falling back to alphabetical.
    static func orderSuggested(_ apps: [CatalogApp]) -> [CatalogApp] {
        let order = Dictionary(uniqueKeysWithValues: suggestedPriority.enumerated().map { ($1, $0) })
        return apps.sorted { a, b in
            let ra = order[a.name.lowercased()] ?? Int.max
            let rb = order[b.name.lowercased()] ?? Int.max
            if ra != rb { return ra < rb }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }

    /// Merges two catalogs, keeping the first occurrence of each app name
    /// (so bundled/curated entries win) and sorting the result by name.
    static func merge(_ primary: [CatalogApp], _ secondary: [CatalogApp]) -> [CatalogApp] {
        var seen = Set<String>()
        var result: [CatalogApp] = []
        for app in primary + secondary {
            let key = app.name.lowercased()
            if seen.insert(key).inserted {
                result.append(app)
            }
        }
        return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: - Remote loading

    private struct RemoteApp: Decodable {
        let name: String
        let url: String
        let isFirstParty: Bool?
    }

    /// Limits to keep the remote feed bounded and safe.
    static let maxCatalogBytes = 5 * 1024 * 1024
    static let maxCatalogEntries = 3000

    /// Schemes we never accept from the remote feed (web/executable schemes).
    private static let blockedSchemes: Set<String> = ["http", "https", "file", "javascript", "data", "about", "blob"]

    /// Whether the remote catalog fetch is enabled (Settings → Privacy, default on).
    static var remoteFetchEnabled: Bool {
        UserDefaults(suiteName: appGroupID)?.object(forKey: "RemoteAppCatalogEnabled") as? Bool ?? true
    }

    /// Synchronous snapshot of everything we know: bundled + fresh cached remote
    /// + fresh cached extra community list.
    static func knownApps() -> [CatalogApp] {
        var result = bundled
        if remoteFetchEnabled, let cached = cachedAppsIfFresh() {
            result = merge(result, cached)
        }
        if extraFetchEnabled, let cached = cachedExtraIfFresh() {
            result = merge(result, cached)
        }
        return result
    }

    /// Whether `name` is a known catalog app (used to gate Apple icon lookups so
    /// we never send free-typed custom names to Apple).
    static func isKnownName(_ name: String) -> Bool {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !n.isEmpty else { return false }
        return knownApps().contains { $0.name.lowercased() == n }
    }

    private static var cacheFileURL: URL? {
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = caches.appendingPathComponent("AppCatalog", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("apps.json")
    }

    /// Fetches the remote catalog (validated), falling back to a fresh disk cache.
    static func fetchRemote() async -> [CatalogApp]? {
        guard remoteFetchEnabled else { return nil }
        if let cached = cachedAppsIfFresh() {
            return cached
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: remoteURL)
            guard data.count <= maxCatalogBytes else { return nil }
            if let http = response as? HTTPURLResponse, http.statusCode != 200 { return nil }
            if let url = cacheFileURL {
                try? data.write(to: url)
            }
            return decodeRemote(data)
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

    /// Treats the remote feed as untrusted: validates shape, size and entry
    /// count, and only accepts well-formed custom URL schemes.
    private static func decodeRemote(_ data: Data) -> [CatalogApp]? {
        guard data.count <= maxCatalogBytes,
              let remote = try? JSONDecoder().decode([RemoteApp].self, from: data),
              !remote.isEmpty, remote.count <= maxCatalogEntries else {
            return nil
        }

        var seen = Set<String>()
        var result: [CatalogApp] = []
        for entry in remote {
            let name = entry.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, name.count <= 100 else { continue }
            guard validScheme(entry.url) != nil else { continue }
            guard !entry.url.lowercased().hasPrefix("shortcuts://") else { continue }
            guard seen.insert(name.lowercased()).inserted else { continue }
            result.append(CatalogApp(name: name, scheme: entry.url, category: (entry.isFirstParty == true ? "Apple" : "Apps")))
        }
        guard !result.isEmpty else { return nil }
        return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Returns the URL scheme if it is a well-formed custom scheme we accept.
    private static func validScheme(_ url: String) -> String? {
        guard let colon = url.firstIndex(of: ":") else { return nil }
        let scheme = String(url[url.startIndex..<colon]).lowercased()
        guard !scheme.isEmpty,
              scheme.range(of: "^[a-z][a-z0-9+.-]*$", options: .regularExpression) != nil,
              !blockedSchemes.contains(scheme) else {
            return nil
        }
        return scheme
    }

    // MARK: - Extra community source (awesome-URLSchemes)

    /// A second, larger community list (markdown). Fetched at runtime, parsed
    /// and validated; entries are not redistributed in the app bundle.
    static let extraURL = URL(string: "https://raw.githubusercontent.com/yishuiliunian/awesome-URLSchemes/master/README.md")!

    /// Whether the extra community list is enabled (Settings → Privacy, default on).
    static var extraFetchEnabled: Bool {
        UserDefaults(suiteName: appGroupID)?.object(forKey: "ExtraAppCatalogEnabled") as? Bool ?? true
    }

    private static var extraCacheFileURL: URL? {
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let dir = caches.appendingPathComponent("AppCatalog", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("awesome.md")
    }

    static func fetchExtra() async -> [CatalogApp]? {
        guard extraFetchEnabled else { return nil }
        if let cached = cachedExtraIfFresh() { return cached }
        do {
            let (data, response) = try await URLSession.shared.data(from: extraURL)
            guard data.count <= maxCatalogBytes else { return nil }
            if let http = response as? HTTPURLResponse, http.statusCode != 200 { return nil }
            if let url = extraCacheFileURL { try? data.write(to: url) }
            return parseAwesome(String(decoding: data, as: UTF8.self))
        } catch {
            return nil
        }
    }

    private static func cachedExtraIfFresh() -> [CatalogApp]? {
        guard let url = extraCacheFileURL,
              let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let modified = attrs[.modificationDate] as? Date,
              Date().timeIntervalSince(modified) < 7 * 24 * 3600,
              let data = try? Data(contentsOf: url) else { return nil }
        return parseAwesome(String(decoding: data, as: UTF8.self))
    }

    /// Parses the `awesome-URLSchemes` markdown (apps section) into catalog
    /// entries. Treated as untrusted input: schemes are validated and deduped.
    private static func parseAwesome(_ text: String) -> [CatalogApp]? {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let regex = try! NSRegularExpression(pattern: "([A-Za-z][A-Za-z0-9+.-]*://[^\\s\\)\\]`|]*)")
        var inApps = false
        var current: String? = nil
        var seen = Set<String>()
        var schemeSeen = Set<String>()
        var out: [CatalogApp] = []

        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("## ") {
                let h = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                inApps = h.contains("应用")
                current = nil
                continue
            }
            if line.hasPrefix("### ") {
                current = cleanMarkdownName(String(line.dropFirst(4)))
                continue
            }
            guard inApps, line.hasPrefix("* ") else { continue }
            let body = String(line.dropFirst(2))
            guard let match = regex.firstMatch(in: body, options: [], range: NSRange(body.startIndex..., in: body)),
                  let r = Range(match.range(at: 1), in: body) else { continue }
            let scheme = String(body[r])
            guard validScheme(scheme) != nil,
                  !scheme.lowercased().hasPrefix("shortcuts://"),
                  !scheme.contains("$"), !scheme.contains("{"), !scheme.contains("}"),
                  isPlainLaunchScheme(scheme),
                  !isIDStyleScheme(scheme) else { continue }
            // One entry per scheme (deep-link variants are filtered above).
            guard schemeSeen.insert(scheme.lowercased()).inserted else { continue }
            let label = String(body[body.startIndex..<r.lowerBound])
                .replacingOccurrences(of: "[", with: "")
                .replacingOccurrences(of: "]", with: "")
                .trimmingCharacters(in: .whitespaces)
            let base = current ?? "App"
            let name = (label.isEmpty || label == "唤起" || label == "打开" || label == "扫一扫")
                ? base : "\(base) – \(label)"
            let trimmedName = String(name.prefix(100))
            guard !trimmedName.isEmpty, seen.insert(trimmedName.lowercased()).inserted else { continue }
            out.append(CatalogApp(name: trimmedName, scheme: scheme, category: "Apps"))
            if out.count >= maxCatalogEntries { break }
        }
        return out.isEmpty ? nil : out.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func cleanMarkdownName(_ s: String) -> String {
        if let r = s.range(of: "](") {
            return s[s.startIndex..<r.lowerBound]
                .replacingOccurrences(of: "[", with: "")
                .trimmingCharacters(in: .whitespaces)
        }
        return s.trimmingCharacters(in: .whitespaces)
    }

    /// Accepts only plain `scheme://` launch URLs (nothing after the scheme) so
    /// deep-link variants (paths, queries, templates) don't clutter the list.
    private static func isPlainLaunchScheme(_ url: String) -> Bool {
        guard let colon = url.firstIndex(of: ":") else { return false }
        let after = url[url.index(after: colon)...]
        guard after.hasPrefix("//") else { return true }
        return after.dropFirst(2).isEmpty
    }

    /// Detects app-scoped numeric IDs (e.g. fb2427617054, db-06fps1zo86up2h9)
    /// that aren't stable, human-usable schemes.
    private static func isIDStyleScheme(_ url: String) -> Bool {
        let name = url.split(separator: ":", maxSplits: 1).first?.lowercased() ?? ""
        if name.range(of: "^[a-z]+[0-9]{6,}$", options: .regularExpression) != nil { return true }
        if name.range(of: "[0-9]{8,}", options: .regularExpression) != nil { return true }
        if name.contains("-"), name.range(of: "[0-9]", options: .regularExpression) != nil { return true }
        return false
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
        var combined = AppCatalog.bundled
        if let remote = await AppCatalog.fetchRemote() {
            combined = AppCatalog.merge(combined, remote)
        }
        if let extra = await AppCatalog.fetchExtra() {
            combined = AppCatalog.merge(combined, extra)
        }
        apps = combined
        isLoading = false
    }
}
