import SwiftUI

/// Soft rounded card surface used across screens for a cohesive look.
struct CardBackground: ViewModifier {
    var cornerRadius: CGFloat = Theme.radiusMedium
    var fill: Color = Theme.surface

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
}

extension View {
    func card(cornerRadius: CGFloat = Theme.radiusMedium, fill: Color = Theme.surface) -> some View {
        modifier(CardBackground(cornerRadius: cornerRadius, fill: fill))
    }
}

/// A calm full-screen warm background used behind most screens.
struct WarmBackground: View {
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            // Soft sunny blobs for playful depth.
            GeometryReader { geo in
                Circle()
                    .fill(Theme.accent.opacity(0.10))
                    .frame(width: geo.size.width * 0.8)
                    .position(x: geo.size.width * 0.15, y: geo.size.height * 0.08)
                Circle()
                    .fill(Theme.star.opacity(0.10))
                    .frame(width: geo.size.width * 0.6)
                    .position(x: geo.size.width * 0.9, y: geo.size.height * 0.9)
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
        }
    }
}
