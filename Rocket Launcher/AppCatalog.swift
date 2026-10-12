//
//  AppCatalog.swift
//  Rocket Launcher
//
//  Bundled directory of popular apps and their URL schemes.
//
//  The catalog is intentionally a plain static list behind this struct so it can
//  later be swapped for a remote source (e.g. a self-hosted server) without
//  changing any UI code.
//

import SwiftUI

struct CatalogApp: Identifiable, Hashable {
    let name: String
    let scheme: String
    let category: String
    let iconName: String // SF Symbol used as a placeholder preview

    var id: String { scheme }
}

enum AppCatalog {
    static let apps: [CatalogApp] = [
        // MARK: Apple
        CatalogApp(name: "Settings", scheme: "App-Prefs:root=", category: "Apple", iconName: "gear"),
        CatalogApp(name: "App Store", scheme: "itms-apps://", category: "Apple", iconName: "bag.fill"),
        CatalogApp(name: "Camera", scheme: "camera://", category: "Apple", iconName: "camera.aperture"),
        CatalogApp(name: "Photos", scheme: "photos-redirect://", category: "Apple", iconName: "photo.on.rectangle.angled"),
        CatalogApp(name: "Maps", scheme: "maps://", category: "Apple", iconName: "map.fill"),
        CatalogApp(name: "Safari", scheme: "https://", category: "Apple", iconName: "safari.fill"),
        CatalogApp(name: "Mail", scheme: "mailto://", category: "Apple", iconName: "envelope.fill"),
        CatalogApp(name: "Phone", scheme: "tel://", category: "Apple", iconName: "phone.fill"),
        CatalogApp(name: "Messages", scheme: "sms://", category: "Apple", iconName: "message.fill"),
        CatalogApp(name: "FaceTime", scheme: "facetime://", category: "Apple", iconName: "video.fill"),
        CatalogApp(name: "Apple Music", scheme: "music://", category: "Apple", iconName: "music.note"),
        CatalogApp(name: "Calendar", scheme: "calshow://", category: "Apple", iconName: "calendar"),
        CatalogApp(name: "Reminders", scheme: "x-apple-reminderkit://", category: "Apple", iconName: "list.bullet"),
        CatalogApp(name: "Notes", scheme: "mobilenotes://", category: "Apple", iconName: "note.text"),
        CatalogApp(name: "Files", scheme: "shareddocuments://", category: "Apple", iconName: "folder.fill"),
        CatalogApp(name: "Podcasts", scheme: "podcasts://", category: "Apple", iconName: "mic.fill"),
        CatalogApp(name: "Books", scheme: "ibooks://", category: "Apple", iconName: "book.fill"),
        CatalogApp(name: "Apple News", scheme: "applenews://", category: "Apple", iconName: "newspaper.fill"),
        CatalogApp(name: "Shortcuts", scheme: "shortcuts://", category: "Apple", iconName: "bolt.fill"),
        CatalogApp(name: "Clock", scheme: "clock://", category: "Apple", iconName: "clock.fill"),

        // MARK: Social
        CatalogApp(name: "Instagram", scheme: "instagram://", category: "Social", iconName: "camera.fill"),
        CatalogApp(name: "Facebook", scheme: "fb://", category: "Social", iconName: "f.circle.fill"),
        CatalogApp(name: "Messenger", scheme: "fb-messenger://", category: "Social", iconName: "message.fill"),
        CatalogApp(name: "WhatsApp", scheme: "whatsapp://", category: "Social", iconName: "phone.circle.fill"),
        CatalogApp(name: "Telegram", scheme: "tg://", category: "Social", iconName: "paperplane.fill"),
        CatalogApp(name: "X / Twitter", scheme: "twitter://", category: "Social", iconName: "bubble.left.fill"),
        CatalogApp(name: "Snapchat", scheme: "snapchat://", category: "Social", iconName: "bell.fill"),
        CatalogApp(name: "TikTok", scheme: "tiktok://", category: "Social", iconName: "waveform"),
        CatalogApp(name: "Discord", scheme: "discord://", category: "Social", iconName: "person.2.fill"),
        CatalogApp(name: "LinkedIn", scheme: "linkedin://", category: "Social", iconName: "briefcase.fill"),
        CatalogApp(name: "Pinterest", scheme: "pinterest://", category: "Social", iconName: "pin.fill"),
        CatalogApp(name: "Tumblr", scheme: "tumblr://", category: "Social", iconName: "quote.bubble.fill"),
        CatalogApp(name: "Reddit", scheme: "reddit://", category: "Social", iconName: "bubble.middle.bottom.fill"),
        CatalogApp(name: "Viber", scheme: "viber://", category: "Social", iconName: "phone.fill"),
        CatalogApp(name: "WeChat", scheme: "weixin://", category: "Social", iconName: "message.fill"),
        CatalogApp(name: "Line", scheme: "line://", category: "Social", iconName: "message.fill"),

        // MARK: Media
        CatalogApp(name: "Spotify", scheme: "spotify://", category: "Media", iconName: "music.note"),
        CatalogApp(name: "YouTube", scheme: "youtube://", category: "Media", iconName: "play.rectangle.fill"),
        CatalogApp(name: "Netflix", scheme: "nflx://", category: "Media", iconName: "play.tv.fill"),
        CatalogApp(name: "Hulu", scheme: "hulu://", category: "Media", iconName: "play.tv.fill"),
        CatalogApp(name: "Disney+", scheme: "disneyplus://", category: "Media", iconName: "play.tv.fill"),
        CatalogApp(name: "Twitch", scheme: "twitch://", category: "Media", iconName: "gamecontroller.fill"),
        CatalogApp(name: "SoundCloud", scheme: "soundcloud://", category: "Media", iconName: "waveform"),
        CatalogApp(name: "Shazam", scheme: "shazam://", category: "Media", iconName: "music.note.list"),
        CatalogApp(name: "Deezer", scheme: "deezer://", category: "Media", iconName: "music.note"),
        CatalogApp(name: "VLC", scheme: "vlc://", category: "Media", iconName: "play.circle.fill"),
        CatalogApp(name: "Audible", scheme: "audible://", category: "Media", iconName: "book.fill"),

        // MARK: Productivity & Utilities
        CatalogApp(name: "Google Chrome", scheme: "googlechrome://", category: "Productivity", iconName: "globe"),
        CatalogApp(name: "Google Search", scheme: "google://", category: "Productivity", iconName: "magnifyingglass"),
        CatalogApp(name: "Google Maps", scheme: "comgooglemaps://", category: "Productivity", iconName: "location.fill"),
        CatalogApp(name: "Gmail", scheme: "googlegmail://", category: "Productivity", iconName: "tray.fill"),
        CatalogApp(name: "Google Drive", scheme: "googledrive://", category: "Productivity", iconName: "folder.fill"),
        CatalogApp(name: "Notion", scheme: "notion://", category: "Productivity", iconName: "doc.richtext.fill"),
        CatalogApp(name: "Slack", scheme: "slack://", category: "Productivity", iconName: "number"),
        CatalogApp(name: "Evernote", scheme: "evernote://", category: "Productivity", iconName: "note.text"),
        CatalogApp(name: "OneNote", scheme: "onenote://", category: "Productivity", iconName: "note.text"),
        CatalogApp(name: "Trello", scheme: "trello://", category: "Productivity", iconName: "list.bullet"),
        CatalogApp(name: "OneDrive", scheme: "ms-onedrive://", category: "Productivity", iconName: "folder.fill"),
        CatalogApp(name: "Zoom", scheme: "zoomus://", category: "Productivity", iconName: "video.fill"),
        CatalogApp(name: "Microsoft Teams", scheme: "msteams://", category: "Productivity", iconName: "person.2.fill"),
        CatalogApp(name: "Outlook", scheme: "ms-outlook://", category: "Productivity", iconName: "envelope.fill"),
        CatalogApp(name: "Things", scheme: "things://", category: "Productivity", iconName: "checkmark.circle.fill"),
        CatalogApp(name: "Todoist", scheme: "todoist://", category: "Productivity", iconName: "checkmark.circle"),
        CatalogApp(name: "Bear", scheme: "bear://", category: "Productivity", iconName: "doc.text.fill"),
        CatalogApp(name: "Notability", scheme: "notability://", category: "Productivity", iconName: "pencil"),
        CatalogApp(name: "GoodNotes", scheme: "goodnotes5://", category: "Productivity", iconName: "pencil.circle"),
        CatalogApp(name: "Fantastical", scheme: "fantastical2://", category: "Productivity", iconName: "calendar"),
        CatalogApp(name: "Spark", scheme: "readdle-spark://", category: "Productivity", iconName: "envelope.fill"),
        CatalogApp(name: "Firefox", scheme: "firefox://", category: "Productivity", iconName: "flame.fill"),
        CatalogApp(name: "Brave", scheme: "brave://", category: "Productivity", iconName: "shield.fill"),
        CatalogApp(name: "1Password", scheme: "onepassword://", category: "Productivity", iconName: "lock.fill"),
        CatalogApp(name: "Bitwarden", scheme: "bitwarden://", category: "Productivity", iconName: "lock.fill"),
        CatalogApp(name: "LastPass", scheme: "lastpass://", category: "Productivity", iconName: "lock.fill"),

        // MARK: Navigation & Transport
        CatalogApp(name: "Waze", scheme: "waze://", category: "Navigation", iconName: "car.fill"),
        CatalogApp(name: "Uber", scheme: "uber://", category: "Navigation", iconName: "car.fill"),
        CatalogApp(name: "Lyft", scheme: "lyft://", category: "Navigation", iconName: "car.fill"),
        CatalogApp(name: "Citymapper", scheme: "citymapper://", category: "Navigation", iconName: "tram.fill"),

        // MARK: Shopping & Finance
        CatalogApp(name: "Amazon", scheme: "amzn://", category: "Shopping", iconName: "cart.fill"),
        CatalogApp(name: "eBay", scheme: "ebay://", category: "Shopping", iconName: "cart.fill"),
        CatalogApp(name: "PayPal", scheme: "paypal://", category: "Finance", iconName: "dollarsign.circle.fill"),
        CatalogApp(name: "Venmo", scheme: "venmo://", category: "Finance", iconName: "dollarsign.circle.fill"),
        CatalogApp(name: "Cash App", scheme: "squarecash://", category: "Finance", iconName: "dollarsign.circle.fill"),

        // MARK: News & Reading
        CatalogApp(name: "Flipboard", scheme: "flipboard://", category: "News", iconName: "newspaper.fill"),
        CatalogApp(name: "Pocket", scheme: "pocket://", category: "News", iconName: "bookmark.fill"),
        CatalogApp(name: "Feedly", scheme: "feedly://", category: "News", iconName: "dot.radiowaves.left.and.right"),

        // MARK: Games
        CatalogApp(name: "Steam", scheme: "steam://", category: "Games", iconName: "gamecontroller.fill")
    ]

    /// A flat search over name and scheme, case-insensitive.
    static func search(_ query: String) -> [CatalogApp] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return apps }
        return apps.filter {
            $0.name.localizedCaseInsensitiveContains(q) ||
            $0.scheme.localizedCaseInsensitiveContains(q)
        }
    }
}
