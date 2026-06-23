import SwiftUI

/// Central design tokens for Packwise. All colors resolve from the asset
/// catalog so they adapt to light/dark mode automatically.
enum Theme {
    // Colors
    static let primary = Color("BrandPrimary")
    static let secondary = Color("BrandSecondary")
    static let background = Color("AppBackground")
    static let surface = Color("CardSurface")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let hairline = Color("Hairline")
    static let success = Color("SuccessGreen")

    // Spacing
    enum Space {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // Corner radii
    enum Radius {
        static let card: CGFloat = 18
        static let chip: CGFloat = 12
        static let pill: CGFloat = 999
    }
}

/// A reusable card container with the app's surface styling.
struct CardBackground: ViewModifier {
    var padding: CGFloat = Theme.Space.lg
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func card(padding: CGFloat = Theme.Space.lg) -> some View {
        modifier(CardBackground(padding: padding))
    }
}
