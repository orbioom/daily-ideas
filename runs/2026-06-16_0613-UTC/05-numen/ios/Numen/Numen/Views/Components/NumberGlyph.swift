import SwiftUI

/// A large gold number glyph used on cards and the share card.
struct NumberGlyph: View {
    let value: Int
    var size: CGFloat = 56
    var isMaster: Bool = false

    var body: some View {
        Text("\(value)")
            .font(.system(size: size, weight: .semibold, design: .serif))
            .foregroundStyle(Theme.goldGradient)
            .shadow(color: Theme.accent.opacity(0.25), radius: isMaster ? 8 : 2)
            .accessibilityHidden(true)
    }
}

/// A small pill tag.
struct TagPill: View {
    let text: String
    var tint: Color = Theme.accent

    var body: some View {
        Text(text)
            .font(Theme.rounded(12, .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tint.opacity(0.14), in: Capsule())
    }
}
