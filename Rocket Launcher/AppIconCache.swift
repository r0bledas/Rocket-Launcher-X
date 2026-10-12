//
//  AppIconCache.swift
//  Rocket Launcher
//
//  Asynchronously loads and caches app icons by name using the iTunes Search
//  API. Icons are cached in memory and on disk so scrolling the catalog only
//  fetches each app once.
//

import SwiftUI
import UIKit

actor AppIconCache {
    static let shared = AppIconCache()

    private var memory: [String: UIImage] = [:]
    private var inFlight: [String: Task<UIImage?, Never>] = [:]

    func icon(named name: String) async -> UIImage? {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !key.isEmpty else { return nil }

        if let cached = memory[key] { return cached }

        if let existing = inFlight[key] {
            return await existing.value
        }

        let task = Task<UIImage?, Never> { () -> UIImage? in
            if let disk = Self.readFromDisk(key: key) { return disk }
            guard let fetched = await Self.fetchIcon(name: name) else { return nil }
            Self.writeToDisk(fetched, key: key)
            return fetched
        }
        inFlight[key] = task
        let image = await task.value
        inFlight[key] = nil
        if let image = image { memory[key] = image }
        return image
    }

    // MARK: - Networking

    private static func fetchIcon(name: String) async -> UIImage? {
        let term = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        guard let url = URL(string: "https://itunes.apple.com/search?term=\(term)&country=us&entity=software&limit=1") else {
            return nil
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]],
                  let first = results.first,
                  let artString = (first["artworkUrl512"] as? String) ?? (first["artworkUrl100"] as? String),
                  let artURL = URL(string: artString) else {
                return nil
            }
            let (imageData, _) = try await URLSession.shared.data(from: artURL)
            return UIImage(data: imageData)
        } catch {
            return nil
        }
    }

    // MARK: - Disk cache

    private static func fileName(for key: String) -> String {
        // Simple, filesystem-safe key.
        let safe = key.replacingOccurrences(of: "/", with: "_")
                       .replacingOccurrences(of: ":", with: "_")
        return "\(safe).png"
    }

    private static func diskURL(key: String) -> URL? {
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = caches.appendingPathComponent("CatalogIcons", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent(fileName(for: key))
    }

    private static func readFromDisk(key: String) -> UIImage? {
        guard let url = diskURL(key: key), let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private static func writeToDisk(_ image: UIImage, key: String) {
        guard let url = diskURL(key: key), let data = image.pngData() else { return }
        try? data.write(to: url)
    }
}

/// Renders a catalog app's icon, fetched asynchronously and cached.
struct CatalogIconView: View {
    let name: String
    var size: CGFloat = 40

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "app.dashed")
                            .font(.system(size: size * 0.4))
                            .foregroundColor(Color.white.opacity(0.35))
                    )
            }
        }
        .task(id: name) {
            image = await AppIconCache.shared.icon(named: name)
        }
        .accessibilityHidden(true)
    }
}
