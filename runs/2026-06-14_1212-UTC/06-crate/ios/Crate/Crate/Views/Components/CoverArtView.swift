import SwiftUI

/// A deterministic gradient "cover" with the record peeking out of its sleeve —
/// no images, fully generated from the record's coverHue + title.
struct CoverArtView: View {
    let title: String
    let artist: String
    let hue: Double
    /// When true a slice of the disc shows behind the sleeve (collection cards).
    var showDisc: Bool = true

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                if showDisc {
                    // Disc peeking from the right edge of the sleeve.
                    VinylDisc(labelHue: hue, labelFraction: 0.38)
                        .frame(width: side * 0.86, height: side * 0.86)
                        .offset(x: side * 0.30)
                }
                // The sleeve (gradient cover).
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Theme.coverGradient(hue: hue))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.black.opacity(0.12), lineWidth: 1)
                    )
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(artist.uppercased())
                                .font(Theme.rounded(9, .heavy))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineLimit(1)
                            Text(title)
                                .font(Theme.serif(13, .bold))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(8)
                        .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                    }
                    .frame(width: showDisc ? side * 0.88 : side, height: showDisc ? side * 0.88 : side)
                    .offset(x: showDisc ? -side * 0.04 : 0)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) by \(artist)")
    }
}
