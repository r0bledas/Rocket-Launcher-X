//
//  LaunchOverlay.swift
//  Rocket Launcher
//
//  A dedicated window that sits above everything (sheets, alerts, etc.) and
//  covers the app during the brief launch/return transition. It shows the
//  user's chosen "launch wallpaper" if set, otherwise black.
//
//  This exists because the app is launched from widgets, opens the target app
//  via its URL scheme, and (without Reduce Motion) shows the standard transition;
//  the overlay keeps that transition looking clean.
//

import SwiftUI
import UIKit

// MARK: - Model (persisted wallpaper)


final class LaunchOverlayModel: ObservableObject {
    static let shared = LaunchOverlayModel()

    @Published private(set) var image: UIImage?

    private let fileName = "LaunchWallpaper.jpg"

    private var fileURL: URL? {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(fileName)
    }

    private init() {
        load()
    }

    private func load() {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else {
            image = nil
            return
        }
        image = UIImage(data: data)
    }

    func setImageData(_ data: Data) {
        guard let picked = UIImage(data: data) else { return }
        let scaled = picked.downscaled(maxDimension: 2400)
        image = scaled

        guard let url = fileURL else { return }
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if let jpeg = scaled.jpegData(compressionQuality: 0.9) {
            try? jpeg.write(to: url)
        }
    }

    func clear() {
        image = nil
        if let url = fileURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

private extension UIImage {
    func downscaled(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension, maxSide > 0 else { return self }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Overlay content

struct LaunchOverlayView: View {
    @ObservedObject var model = LaunchOverlayModel.shared

    var body: some View {
        ZStack {
            if let image = model.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Top-level window


final class LaunchOverlayWindow {
    static let shared = LaunchOverlayWindow()

    private var window: UIWindow?
    private var hideWork: DispatchWorkItem?
    private var scene: UIWindowScene?

    private init() {}

    func show() {
        hideWork?.cancel()
        guard let scene = resolveScene() else { return }
        self.scene = scene

        if window == nil || window?.windowScene !== scene {
            let hosting = UIHostingController(rootView: LaunchOverlayView())
            hosting.view.backgroundColor = .black

            let w = UIWindow(windowScene: scene)
            w.windowLevel = .alert + 1 // above sheets and alerts
            w.rootViewController = hosting
            w.isHidden = true
            window = w
        }

        window?.isHidden = false
    }

    func hide(after delay: TimeInterval) {
        hideWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.window?.isHidden = true
        }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func resolveScene() -> UIWindowScene? {
        if let scene, scene.activationState != .unattached {
            return scene
        }
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first(where: {
            $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive
        }) ?? scenes.first
    }
}
