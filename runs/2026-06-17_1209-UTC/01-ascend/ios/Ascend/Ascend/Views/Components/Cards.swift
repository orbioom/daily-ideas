import SwiftUI

/// Heavy rounded card container used across the app.
struct Card<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.surface)
            )
    }
}

/// Small rounded label chip (muscle group, tag, etc.).
struct Pill: View {
    let text: String
    var color: Color = Theme.steel
    var filled: Bool = false

    var body: some View {
        Text(text)
            .font(Theme.rounded(12, .semibold))
            .foregroundStyle(filled ? .white : color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(filled ? color : color.opacity(0.15))
            )
    }
}

/// Muscle-group badge with icon.
struct MuscleBadge: View {
    let group: MuscleGroup
    var body: some View {
        Label(group.label, systemImage: group.symbol)
            .font(Theme.rounded(12, .semibold))
            .foregroundStyle(group.hue)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(group.hue.opacity(0.15)))
            .accessibilityLabel("Muscle group: \(group.label)")
    }
}
