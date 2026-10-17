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
        CatalogApp(name: "Weather", scheme: "weather://", category: "Apple"),
        CatalogApp(name: "Voice Memos", scheme: "voicememos://", category: "Apple"),
        CatalogApp(name: "Find My", scheme: "findmy://", category: "Apple"),
        CatalogApp(name: "Wallet", scheme: "shoebox://", category: "Apple"),
        CatalogApp(name: "Contacts", scheme: "contacts://", category: "Apple"),
        CatalogApp(name: "Freeform", scheme: "freeform://", category: "Apple"),
        CatalogApp(name: "Journal", scheme: "moments://", category: "Apple"),
        CatalogApp(name: "Tips", scheme: "x-apple-tips://", category: "Apple"),
        CatalogApp(name: "Games", scheme: "games://", category: "Apple"),
        CatalogApp(name: "GarageBand", scheme: "garageband://", category: "Apple"),
        CatalogApp(name: "iMovie", scheme: "imovie://", category: "Apple"),
        CatalogApp(name: "Clips", scheme: "clips://", category: "Apple"),
        CatalogApp(name: "iTunes Store", scheme: "itms://", category: "Apple"),
        CatalogApp(name: "Remote", scheme: "remote://", category: "Apple"),
        CatalogApp(name: "Watch", scheme: "itms-watchs://", category: "Apple"),
        CatalogApp(name: "Magnifier", scheme: "magnifier://", category: "Apple"),
        CatalogApp(name: "Apple Music Classical", scheme: "classical://", category: "Apple"),
        CatalogApp(name: "Health", scheme: "x-apple-health://", category: "Apple"),
        CatalogApp(name: "Fitness", scheme: "x-apple-fitness://", category: "Apple"),

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
        CatalogApp(name: "Threads", scheme: "barcelona://", category: "Social"),

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
        CatalogApp(name: "CapCut", scheme: "capcut://", category: "Media"),
        CatalogApp(name: "Amazon Prime Video", scheme: "aiv://", category: "Media"),
        CatalogApp(name: "Tubi", scheme: "tubi://", category: "Media"),
        CatalogApp(name: "Peacock", scheme: "peacock://", category: "Media"),

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
        CatalogApp(name: "Duolingo", scheme: "duolingo://", category: "Productivity"),
        CatalogApp(name: "Canva", scheme: "canva://", category: "Productivity"),
        CatalogApp(name: "Microsoft Word", scheme: "ms-word://", category: "Productivity"),
        CatalogApp(name: "Adobe Acrobat Reader", scheme: "acrobat://", category: "Productivity"),
        CatalogApp(name: "Indeed", scheme: "indeed://", category: "Productivity"),

        // MARK: Utilities
        CatalogApp(name: "Mi Telcel", scheme: "mitelcel://", category: "Utilities"),
        CatalogApp(name: "SmartFlow", scheme: "smartflow://", category: "Utilities"),
        CatalogApp(name: "Windy.com", scheme: "windy://", category: "Utilities"),
        CatalogApp(name: "Life360", scheme: "life360://", category: "Utilities"),

        // MARK: Navigation & Transport
        CatalogApp(name: "Waze", scheme: "waze://", category: "Navigation"),
        CatalogApp(name: "Uber", scheme: "uber://", category: "Navigation"),
        CatalogApp(name: "Lyft", scheme: "lyft://", category: "Navigation"),
        CatalogApp(name: "Citymapper", scheme: "citymapper://", category: "Navigation"),
        CatalogApp(name: "Rappi", scheme: "rappi://", category: "Navigation"),
        CatalogApp(name: "DiDi Rider", scheme: "didi://", category: "Navigation"),

        // MARK: Shopping & Finance
        CatalogApp(name: "Amazon", scheme: "amzn://", category: "Shopping"),
        CatalogApp(name: "Amazon MX", scheme: "https://www.amazon.com.mx/", category: "Shopping"),
        CatalogApp(name: "Amazon US", scheme: "https://www.amazon.com/", category: "Shopping"),
        CatalogApp(name: "Mercado Libre", scheme: "https://www.mercadolibre.com.mx/", category: "Shopping"),
        CatalogApp(name: "eBay", scheme: "ebay://", category: "Shopping"),
        CatalogApp(name: "Temu", scheme: "temu://", category: "Shopping"),
        CatalogApp(name: "SHEIN", scheme: "shein://", category: "Shopping"),
        CatalogApp(name: "AliExpress", scheme: "aliexpress://", category: "Shopping"),
        CatalogApp(name: "Vinted", scheme: "vinted://", category: "Shopping"),
        CatalogApp(name: "DoorDash", scheme: "doordash://", category: "Shopping"),
        CatalogApp(name: "McDonald's", scheme: "mcdonalds://", category: "Shopping"),
        CatalogApp(name: "PayPal", scheme: "paypal://", category: "Finance"),
        CatalogApp(name: "Venmo", scheme: "venmo://", category: "Finance"),
        CatalogApp(name: "Cash App", scheme: "squarecash://", category: "Finance"),
        CatalogApp(name: "BBVA", scheme: "bbvamovilmx://", category: "Finance"),
        CatalogApp(name: "Mercado Pago", scheme: "mercadopago://", category: "Finance"),
        CatalogApp(name: "Nu", scheme: "https://nubank.com.br", category: "Finance"),
        CatalogApp(name: "Chime", scheme: "chime://", category: "Finance"),

        // MARK: News & Reading
        CatalogApp(name: "Flipboard", scheme: "flipboard://", category: "News"),
        CatalogApp(name: "Pocket", scheme: "pocket://", category: "News"),
        CatalogApp(name: "Feedly", scheme: "feedly://", category: "News"),

        // MARK: Games
        CatalogApp(name: "Steam", scheme: "steam://", category: "Games"),
        CatalogApp(name: "Clash Royale", scheme: "clashroyale://", category: "Games"),
        CatalogApp(name: "Brawl Stars", scheme: "brawlstars://", category: "Games"),
        CatalogApp(name: "Minecraft", scheme: "minecraft://", category: "Games"),
        CatalogApp(name: "Chess", scheme: "fb2427617054://", category: "Games"),
        CatalogApp(name: "Roblox", scheme: "roblox://", category: "Games"),
        CatalogApp(name: "Block Blast!", scheme: "blockblast://", category: "Games"),

        // MARK: Additional major apps
        CatalogApp(name: "Signal", scheme: "sgnl://", category: "Social"),
        CatalogApp(name: "WhatsApp Business", scheme: "whatsapp-smb://", category: "Social"),
        CatalogApp(name: "imo", scheme: "imo://", category: "Social"),
        CatalogApp(name: "Truecaller", scheme: "truecaller://", category: "Social"),
        CatalogApp(name: "Bluesky", scheme: "bluesky://", category: "Social"),
        CatalogApp(name: "BeReal", scheme: "bereal://", category: "Social"),
        CatalogApp(name: "Google Voice", scheme: "googlevoice://", category: "Social"),
        CatalogApp(name: "YouTube Music", scheme: "youtubemusic://", category: "Media"),
        CatalogApp(name: "Max", scheme: "hbomax://", category: "Media"),
        CatalogApp(name: "Paramount+", scheme: "paramountplus://", category: "Media"),
        CatalogApp(name: "Apple TV", scheme: "videos://", category: "Media"),
        CatalogApp(name: "Crunchyroll", scheme: "crunchyroll://", category: "Media"),
        CatalogApp(name: "Kindle", scheme: "kindle://", category: "Media"),
        CatalogApp(name: "Tidal", scheme: "tidal://", category: "Media"),
        CatalogApp(name: "Perplexity", scheme: "perplexity://", category: "Productivity"),
        CatalogApp(name: "Google Docs", scheme: "googledocs://", category: "Productivity"),
        CatalogApp(name: "Google Sheets", scheme: "googlesheets://", category: "Productivity"),
        CatalogApp(name: "Google Translate", scheme: "googletranslate://", category: "Productivity"),
        CatalogApp(name: "Google Photos", scheme: "googlephotos://", category: "Media"),
        CatalogApp(name: "Google Calendar", scheme: "googlecalendar://", category: "Productivity"),
        CatalogApp(name: "Google Authenticator", scheme: "googleauthenticator://", category: "Productivity"),
        CatalogApp(name: "Google Pay", scheme: "gpay://", category: "Finance"),
        CatalogApp(name: "Microsoft Excel", scheme: "ms-excel://", category: "Productivity"),
        CatalogApp(name: "Microsoft PowerPoint", scheme: "ms-powerpoint://", category: "Productivity"),
        CatalogApp(name: "InShot", scheme: "inshot://", category: "Productivity"),
        CatalogApp(name: "Free Fire MAX", scheme: "freefiremax://", category: "Games"),
        CatalogApp(name: "Ludo King", scheme: "ludoking://", category: "Games"),
        CatalogApp(name: "Candy Crush Saga", scheme: "candycrushsaga://", category: "Games"),
        CatalogApp(name: "Subway Surfers", scheme: "subwaysurfers://", category: "Games"),
        CatalogApp(name: "Clash of Clans", scheme: "clashofclans://", category: "Games"),
        CatalogApp(name: "Genshin Impact", scheme: "genshinimpact://", category: "Games"),
        CatalogApp(name: "Uber Eats", scheme: "ubereats://", category: "Shopping"),
        CatalogApp(name: "Walmart", scheme: "walmart://", category: "Shopping"),
        CatalogApp(name: "Target", scheme: "target://", category: "Shopping"),
        CatalogApp(name: "Etsy", scheme: "etsy://", category: "Shopping"),
        CatalogApp(name: "Instacart", scheme: "instacart://", category: "Shopping"),
        CatalogApp(name: "Booking.com", scheme: "booking://", category: "Navigation"),
        CatalogApp(name: "Expedia", scheme: "expedia://", category: "Navigation"),
        CatalogApp(name: "Airbnb", scheme: "airbnb://", category: "Navigation"),
        CatalogApp(name: "Revolut", scheme: "revolut://", category: "Finance"),
        CatalogApp(name: "Wise", scheme: "wise://", category: "Finance"),
        CatalogApp(name: "Robinhood", scheme: "robinhood://", category: "Finance"),
        CatalogApp(name: "Coinbase", scheme: "coinbase://", category: "Finance"),
        CatalogApp(name: "Chase", scheme: "chase://", category: "Finance"),
        CatalogApp(name: "Wells Fargo", scheme: "wellsfargo://", category: "Finance"),
        CatalogApp(name: "Capital One", scheme: "capitalone://", category: "Finance"),
        CatalogApp(name: "NordVPN", scheme: "nordvpn://", category: "Utilities"),
        CatalogApp(name: "ExpressVPN", scheme: "expressvpn://", category: "Utilities"),
        CatalogApp(name: "Speedtest", scheme: "speedtest://", category: "Utilities"),
        CatalogApp(name: "Dropbox", scheme: "dbapi-1://", category: "Productivity"),
        CatalogApp(name: "CVS", scheme: "cvs://", category: "Utilities"),
        CatalogApp(name: "Walgreens", scheme: "walgreens://", category: "Utilities")
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

    /// Number of curated apps shown in the picker's "Suggested" section.
    static let suggestedLimit = 28

    /// Top free apps by downloads, in order, from AppMagic's top charts
    /// (worldwide, App Store, 2026-10-15). Unsupported chart entries are
    /// skipped, so this is the top `suggestedLimit` apps we can launch.
    static let suggestedPriority: [String] = [
        "chatgpt", "whatsapp", "tiktok", "instagram", "facebook", "snapchat",
        "telegram", "roblox", "messenger", "capcut", "pinterest", "gemini",
        "spotify", "block blast!", "claude", "threads", "youtube", "duolingo",
        "zoom", "x / twitter", "canva", "temu", "uber", "firefox", "amazon",
        "netflix", "microsoft teams", "microsoft word"
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

    /// Synchronous snapshot of everything we know: bundled + fresh cached remote.
    static func knownApps() -> [CatalogApp] {
        var result = bundled
        if remoteFetchEnabled, let cached = cachedAppsIfFresh() {
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
        apps = combined
        isLoading = false
    }
}
