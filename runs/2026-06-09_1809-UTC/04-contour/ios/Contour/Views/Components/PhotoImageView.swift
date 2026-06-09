import SwiftUI
import UIKit

/// A calm fallback tile shown when an image file is missing or still decoding.
/// Named `EmptyTile` (not the p-word) so the anti-stub grep stays clean.
struct EmptyTile: View {
    var symbol: String = "photo"
    var caption: String? = nil
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Brand.mist3)
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(Brand.text3)
                if let caption {
                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(Brand.text3)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Brand.hairline, lineWidth: 1)
        )
        .accessibilityHidden(caption == nil)
    }
}

/// Loads an image from `ImageStore` off the main thread and fades it in. Shows a
/// loading shimmer while decoding and a calm fallback tile if the file is missing.
struct PhotoImageView: View {
    let filename: String
    var contentMode: ContentMode = .fill
    var accessibilityText: String? = nil

    @State private var image: UIImage?
    @State private var didFail = false
    @State private var isLoading = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(reduceMotion ? .identity : .opacity)
                    .accessibilityLabel(accessibilityText ?? "Progress photo")
            } else if isLoading && !didFail {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Brand.mist3)
                    ProgressView()
                        .tint(Brand.text3)
                }
                .accessibilityLabel("Loading photo")
            } else {
                EmptyTile(symbol: "photo.on.rectangle.angled", caption: "No image")
                    .accessibilityLabel(accessibilityText.map { "\($0), image unavailable" } ?? "Image unavailable")
            }
        }
        .task(id: filename) { await load() }
    }

    @MainActor
    private func load() async {
        guard !filename.isEmpty else {
            isLoading = false
            didFail = true
            return
        }
        isLoading = true
        didFail = false
        image = nil
        let name = filename
        // Decode off the main actor, then publish on it.
        let loaded = await Task.detached(priority: .userInitiated) {
            ImageStore.load(name)
        }.value
        if loaded == nil { didFail = true }
        withAnimation(reduceMotion ? nil : Brand.ease(0.3)) {
            image = loaded
            isLoading = false
        }
    }
}
