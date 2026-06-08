import SwiftUI

/// A clean, photo-free visual for a clothing item: a color field with the
/// category glyph. Reliable and fast — no image decoding to crash on.
struct ItemSwatch: View {
    let colorHex: UInt32
    let symbol: String
    var size: CGFloat = 80
    var corner: CGFloat = 16

    private var swatch: Color { Color(hex: colorHex) }
    private var isLight: Bool {
        let r = Double((colorHex >> 16) & 0xFF)
        let g = Double((colorHex >> 8) & 0xFF)
        let b = Double(colorHex & 0xFF)
        let luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
        return luminance > 0.6
    }

    var body: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(
                LinearGradient(colors: [swatch.opacity(0.9), swatch],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(
                Image(systemName: symbol)
                    .font(.system(size: size * 0.34, weight: .medium))
                    .foregroundStyle((isLight ? Color.black : Color.white).opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1)
            )
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
