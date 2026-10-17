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
        setImage(picked)
    }

    func setImage(_ picked: UIImage) {
        let scaled = picked.normalizedUp().downscaled(maxDimension: 2400)
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

    /// Bakes EXIF orientation into the pixels so aspect-ratio math is reliable.
    func normalizedUp() -> UIImage {
        guard imageOrientation != .up else { return self }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
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

// MARK: - Crop (for images that don't match the device aspect ratio)

struct WallpaperCropView: View {
    let image: UIImage
    let onCancel: () -> Void
    let onUse: (UIImage) -> Void

    @State private var offset: CGSize = .zero
    @State private var committedOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            let frame = geo.size
            let display = displaySize(in: frame)
            let current = clamped(
                CGSize(width: committedOffset.width + offset.width,
                       height: committedOffset.height + offset.height),
                display: display,
                frame: frame
            )

            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .frame(width: display.width, height: display.height)
                    .offset(x: current.width, y: current.height)
                    .frame(width: frame.width, height: frame.height)
                    .clipped()
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { offset = $0.translation }
                            .onEnded { value in
                                committedOffset = clamped(
                                    CGSize(width: committedOffset.width + value.translation.width,
                                           height: committedOffset.height + value.translation.height),
                                    display: display,
                                    frame: frame
                                )
                                offset = .zero
                            }
                    )
            }
        }
        .ignoresSafeArea()
        .overlay(alignment: .bottom) {
            Button {
                onUse(renderCrop())
            } label: {
                Text("Use Image")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .overlay(alignment: .top) {
            HStack {
                Button("Cancel") { onCancel() }
                    .foregroundColor(.white)
                Spacer()
                Text("Drag to position")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Color.clear.frame(width: 52, height: 1)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }

    private func displaySize(in frame: CGSize) -> CGSize {
        guard image.size.width > 0, image.size.height > 0 else { return frame }
        let scale = max(frame.width / image.size.width, frame.height / image.size.height)
        return CGSize(width: image.size.width * scale, height: image.size.height * scale)
    }

    private func clamped(_ offset: CGSize, display: CGSize, frame: CGSize) -> CGSize {
        let maxX = max(0, (display.width - frame.width) / 2)
        let maxY = max(0, (display.height - frame.height) / 2)
        return CGSize(width: min(max(offset.width, -maxX), maxX),
                      height: min(max(offset.height, -maxY), maxY))
    }

    private func renderCrop() -> UIImage {
        let frame = UIScreen.main.bounds.size
        let display = displaySize(in: frame)
        let clampedOffset = clamped(committedOffset, display: display, frame: frame)
        let renderer = UIGraphicsImageRenderer(size: frame)
        return renderer.image { _ in
            let origin = CGPoint(
                x: (frame.width - display.width) / 2 + clampedOffset.width,
                y: (frame.height - display.height) / 2 + clampedOffset.height
            )
            image.draw(in: CGRect(origin: origin, size: display))
        }
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
