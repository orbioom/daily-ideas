import SwiftUI

/// A generated book "cover": a deterministic gradient (from `colorSeed`) with the
/// title/author initials and a spine motif. No bundled images.
struct BookCover: View {
    let title: String
    let author: String
    let colorSeed: Int
    let initials: String
    var asGradient: Bool = true
    var cornerRadius: CGFloat = 10

    /// Two-stop palette derived deterministically from the seed.
    private var palette: (top: Color, bottom: Color) {
        BookCover.palette(for: colorSeed)
    }

    static func palette(for seed: Int) -> (top: Color, bottom: Color) {
        // A curated set of warm, library-friendly cover pairs.
        let pairs: [(UInt, UInt)] = [
            (0xB5651D, 0x7A3E12), // amber → umber
            (0x9C4A3C, 0x5E261E), // brick → maroon
            (0x4E6E5D, 0x29403A), // sage → forest
            (0x3C5A78, 0x1F3147), // slate → navy
            (0x7A5C8E, 0x432F54), // plum → aubergine
            (0xC08438, 0x8A5A1B), // ochre → bronze
            (0x6E7B3D, 0x404926), // olive → moss
            (0x8E5A3C, 0x53301C), // terracotta → cocoa
            (0x40707A, 0x234146), // teal → deep teal
            (0xA84C5E, 0x6B2937)  // rose → wine
        ]
        let idx = ((seed % pairs.count) + pairs.count) % pairs.count
        let pair = pairs[idx]
        return (Color(hex: pair.0), Color(hex: pair.1))
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .bottomLeading) {
                background
                // Spine motif: a thin darker band on the left edge.
                Rectangle()
                    .fill(Color.black.opacity(0.18))
                    .frame(width: max(3, w * 0.06))
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text(initials)
                        .font(Theme.serif(min(34, w * 0.34), .bold))
                        .foregroundStyle(.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                    Spacer(minLength: 0)
                    Text(title)
                        .font(Theme.serif(min(13, w * 0.13), .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    Text(author)
                        .font(Theme.rounded(min(11, w * 0.11), .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                }
                .padding(.horizontal, max(8, w * 0.1))
                .padding(.vertical, max(8, w * 0.1))
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
            )
        }
        .aspectRatio(2.0 / 3.0, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cover of \(title) by \(author)")
    }

    @ViewBuilder
    private var background: some View {
        if asGradient {
            LinearGradient(colors: [palette.top, palette.bottom],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            palette.top
        }
    }
}
