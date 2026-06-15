import SwiftUI

/// A small live render of an empty (or suggestion-tinted) page, used in the gallery grid.
struct PagePreviewThumb: View {
    let page: ColoringPage
    let side: CGFloat
    var palette: Palette

    var body: some View {
        // Show a light "suggested" preview: faint suggested colors so the page reads
        // as art rather than blank, without implying it's already colored.
        PageCanvasView(page: page, fills: previewFills, palette: palette,
                       showOutlines: true, showNumbers: false)
            .frame(width: side, height: side)
            .background(Color(hex: 0xFFFFFF))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
            .accessibilityHidden(true)
    }

    private var previewFills: [Int: String] {
        var f: [Int: String] = [:]
        // Tint roughly every 3rd region with a soft suggested color for a teaser look.
        for (i, region) in page.regions.enumerated() where i % 3 == 0 {
            let base = palette.color(at: region.suggestedColorIndex)
            f[region.id] = base.opacity(0.5).hexBlendedOnWhite
        }
        return f
    }
}

/// A live render of a saved artwork using its persisted fills.
struct ArtworkThumb: View {
    let artwork: Artwork
    let page: ColoringPage
    var palette: Palette
    let side: CGFloat

    var body: some View {
        Group {
            if let data = artwork.thumbnailData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                PageCanvasView(page: page, fills: artwork.fills, palette: palette,
                               showOutlines: true, showNumbers: false)
            }
        }
        .frame(width: side, height: side)
        .background(Color(hex: 0xFFFFFF))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
        .accessibilityHidden(true)
    }
}

/// A compact progress pill: "12 / 40" with a thin bar.
struct ProgressBadge: View {
    let filled: Int
    let total: Int

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(filled) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.hairline)
                    Capsule().fill(Theme.accent)
                        .frame(width: max(0, geo.size.width * fraction))
                }
            }
            .frame(height: 5)
            Text("\(Int(fraction * 100))%")
                .font(Theme.rounded(11, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
    }
}

private extension Color {
    /// Approximate the on-white appearance of a translucent color as an opaque hex,
    /// since Canvas fills want solid colors for crisp thumbnails.
    var hexBlendedOnWhite: String {
        let ui = UIColor(self)
        var r: CGFloat = 1, g: CGFloat = 1, b: CGFloat = 1, a: CGFloat = 1
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return "FFFFFF" }
        let br = r * a + (1 - a)
        let bg = g * a + (1 - a)
        let bb = b * a + (1 - a)
        return String(format: "%02X%02X%02X",
                      Int((br * 255).rounded()),
                      Int((bg * 255).rounded()),
                      Int((bb * 255).rounded()))
    }
}
