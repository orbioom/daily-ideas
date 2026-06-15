import SwiftUI

/// A single rendered Mahjong tile: ivory face with a beveled edge for depth,
/// the suit glyph, and selection / hint / free highlighting.
struct TileView: View {
    let placed: PlacedTile
    let size: CGSize
    let isSelected: Bool
    let isHinted: Bool
    let isFree: Bool
    let showFreeHint: Bool
    let themeTint: Color

    /// Depth offset applied per layer to fake 3D stacking.
    static let layerOffset: CGFloat = 6

    private var corner: CGFloat { min(size.width, size.height) * 0.16 }
    private var bevel: CGFloat { min(size.width, size.height) * 0.12 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Bevel / side (creates the 3D thickness look).
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Theme.tileEdge)
                .offset(x: bevel * 0.5, y: bevel)

            // Face.
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(faceGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: isSelected ? 2.5 : 1)
                )
                .overlay(glyphLayer)
                .overlay(freeHintOverlay)
        }
        .frame(width: size.width, height: size.height)
        .shadow(color: Color.black.opacity(0.18), radius: 2, x: 1, y: 2)
    }

    private var faceGradient: LinearGradient {
        LinearGradient(
            colors: [Theme.tileFace, Theme.tileFaceShadow],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var borderColor: Color {
        if isSelected { return Theme.accent }
        if isHinted { return Theme.gold }
        return Theme.tileEdge
    }

    private var glyphLayer: some View {
        TileGlyphView(face: placed.face, tint: themeTint)
            .padding(min(size.width, size.height) * 0.1)
    }

    @ViewBuilder
    private var freeHintOverlay: some View {
        if showFreeHint && isFree && !isSelected && !isHinted {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .strokeBorder(Theme.good.opacity(0.5), lineWidth: 1.5)
        } else if isHinted {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Theme.gold.opacity(0.22))
        } else if isSelected {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Theme.accent.opacity(0.16))
        }
    }
}
