import SwiftUI

/// Standard surface card styling used across the app.
struct CardSurface: ViewModifier {
    var padding: CGFloat = 16
    var radius: CGFloat = Theme.radiusM

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func cardSurface(padding: CGFloat = 16, radius: CGFloat = Theme.radiusM) -> some View {
        modifier(CardSurface(padding: padding, radius: radius))
    }

    /// Standard screen background.
    func screenBackground() -> some View {
        background(Theme.bg.ignoresSafeArea())
    }
}
