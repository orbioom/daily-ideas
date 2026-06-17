import SwiftUI

/// Renders a `WallpaperSpec` using a SwiftUI `Canvas`. Used for the live preview,
/// library thumbnails, and (via `ImageRenderer`) high-resolution export.
struct WallpaperCanvasView: View {
    let spec: WallpaperSpec

    var body: some View {
        Canvas(opaque: true, rendersAsynchronously: false) { context, size in
            var ctx = context
            WallpaperRenderer.draw(spec, in: &ctx, size: size)
        }
    }
}

/// A convenience wrapper that frames a wallpaper at a given aspect ratio with rounded corners.
struct WallpaperPreview: View {
    let spec: WallpaperSpec
    var aspect: CGFloat = AspectRatioOption.phone.ratio
    var cornerRadius: CGFloat = Theme.radius

    var body: some View {
        WallpaperCanvasView(spec: spec)
            .aspectRatio(aspect, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
            .accessibilityElement()
            .accessibilityLabel("Wallpaper preview")
            .accessibilityValue("\(spec.style.displayName), palette \(spec.paletteName)")
    }
}
