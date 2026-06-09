import SwiftUI

/// A compact glass stat tile: a big mono value over a label.
struct StatTile: View {
    let value: String
    let label: String
    var tint: Color = Brand.text

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(Brand.mono(24, weight: .semibold))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label.uppercased())
                .font(Brand.mono(11, weight: .medium))
                .tracking(1.1)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// A small section title used above grouped content.
struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Brand.text)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A small tinted chip with an SF Symbol and a label (sport / format).
struct TagChip: View {
    let symbol: String
    let label: String
    var tint: Color = Brand.text2

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.caption2.weight(.semibold))
                .accessibilityHidden(true)
            Text(label)
                .font(Brand.mono(12, weight: .medium))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(tint.opacity(0.14), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }
}

/// A circular avatar showing a player's initials over a soft fill.
struct PlayerAvatar: View {
    let initials: String
    var isMe: Bool = false
    var size: CGFloat = 40

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
            .foregroundStyle(isMe ? .white : Brand.text)
            .frame(width: size, height: size)
            .background(
                Circle().fill(isMe ? AnyShapeStyle(Brand.inkGradient)
                                   : AnyShapeStyle(Brand.hairline))
            )
            .accessibilityHidden(true)
    }
}

/// A bold W or L result badge.
struct ResultBadge: View {
    let didWin: Bool
    var body: some View {
        Text(didWin ? "W" : "L")
            .font(.system(size: 16, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(Circle().fill(didWin ? Brand.live : Brand.danger))
            .accessibilityLabel(didWin ? "Win" : "Loss")
    }
}
