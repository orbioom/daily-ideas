import SwiftUI

/// Renders a chess piece as a styled Unicode glyph (no image assets required).
///
/// We always use the filled (black) Unicode glyphs and color them ourselves. White pieces
/// are drawn as a dark "outline" glyph with a cream glyph layered on top, giving a clean,
/// readable tournament look on both light and dark squares.
struct PieceGlyph: View {
    let piece: Piece
    let size: CGFloat
    var style: PieceStyle = .classic

    var body: some View {
        ZStack {
            if piece.color == .white {
                // Dark border layer (slightly larger) then cream fill on top.
                Text(piece.glyph)
                    .foregroundStyle(Color(hex: 0x16140F))
                    .font(.system(size: size, weight: borderWeight))
                Text(piece.glyph)
                    .foregroundStyle(Color(hex: 0xFBF8F1))
                    .font(.system(size: size * 0.92, weight: fillWeight))
            } else {
                Text(piece.glyph)
                    .foregroundStyle(Color(hex: 0x16140F))
                    .font(.system(size: size, weight: fillWeight))
                    .shadow(color: .black.opacity(0.18), radius: 0.5, y: 0.5)
            }
        }
        .accessibilityHidden(true)
    }

    private var fillWeight: Font.Weight { style == .bold ? .black : .regular }
    private var borderWeight: Font.Weight { style == .bold ? .black : .semibold }
}
