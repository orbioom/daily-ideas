import SwiftUI

/// A round, friendly avatar showing the profile's initial on its color.
struct AvatarBubble: View {
    let initial: String
    let color: Color
    var size: CGFloat = 56
    var selected: Bool = false

    var body: some View {
        Text(initial)
            .font(Theme.rounded(size * 0.44, .heavy))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                Circle().fill(
                    LinearGradient(
                        colors: [color.opacity(0.85), color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            )
            .overlay(
                Circle().strokeBorder(
                    selected ? Theme.accent : .white.opacity(0.5),
                    lineWidth: selected ? 4 : 2
                )
            )
            .shadow(color: color.opacity(0.35), radius: 6, y: 3)
            .accessibilityHidden(true)
    }
}
