import SwiftUI

/// A small mood indicator. Decorative chrome is hidden from VoiceOver; the
/// surrounding row supplies the spoken label.
struct MoodGlyph: View {
    let mood: Int
    var size: CGFloat = 28

    private var resolved: Mood? { Mood(rawValue: mood) }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.18))
            Image(systemName: symbol)
                .font(.system(size: size * 0.5, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var color: Color {
        guard let r = resolved else { return Brand.text3 }
        return Color(hex: r.colorHex)
    }
    private var symbol: String {
        resolved?.symbol ?? "circle.dashed"
    }
}

struct TagChip: View {
    let name: String
    let colorHex: UInt32
    var body: some View {
        Text(name)
            .font(Brand.mono(11, weight: .medium))
            .foregroundStyle(Color(hex: colorHex))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color(hex: colorHex).opacity(0.14),
                        in: Capsule())
    }
}
