import SwiftUI

/// Loads a moment's image from the ImageStore off the main thread, downsampled
/// to the requested point size. Shows a gradient fallback while loading and a
/// graceful "missing photo" state if the file is gone.
struct MomentImageView: View {
    let filename: String?
    /// The approximate display size in points; drives downsampling.
    var pointSize: CGFloat = 200
    var cornerRadius: CGFloat = Theme.tileRadius
    /// When true, loads full resolution (used in detail view).
    var fullResolution: Bool = false

    @State private var image: UIImage?
    @State private var didLoad = false
    @State private var missing = false

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if missing {
                fallbackTile(symbol: "photo.badge.exclamationmark", text: "Photo unavailable")
            } else if filename == nil {
                fallbackTile(symbol: "camera", text: nil)
            } else {
                // loading
                Rectangle()
                    .fill(Theme.surfaceAlt)
                    .overlay(ProgressView().tint(Theme.inkSoft))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .task(id: filename) { await load() }
        .accessibilityHidden(true)
    }

    private func fallbackTile(symbol: String, text: String?) -> some View {
        ZStack {
            Theme.heroGradient.opacity(0.20)
            Theme.surfaceAlt.opacity(0.5)
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.inkSoft)
                if let text {
                    Text(text)
                        .font(Theme.rounded(11, .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
    }

    private func load() async {
        guard let filename, !filename.isEmpty else {
            image = nil
            missing = false
            return
        }
        let full = fullResolution
        let size = pointSize
        let loaded = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            if full {
                return ImageStore.shared.loadFull(filename)
            } else {
                return ImageStore.shared.loadThumbnail(filename, pointSize: size)
            }
        }.value
        await MainActor.run {
            if let loaded {
                image = loaded
                missing = false
            } else {
                image = nil
                missing = true
            }
            didLoad = true
        }
    }
}
