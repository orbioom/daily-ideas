import SwiftUI

/// Central palette + spacing tokens. All colors resolve from the asset catalog
/// so light and dark mode are first-class everywhere.
enum Theme {
    // Surfaces
    static let bg = Color("BackgroundPrimary")
    static let bgSecondary = Color("BackgroundSecondary")
    static let card = Color("CardSurface")
    static let hairline = Color("HairlineSeparator")

    // Text
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")

    // Brand + semantic
    static let accent = Color("AccentColor")
    static let overdue = Color("OverdueRed")
    static let due = Color("DueAmber")
    static let ok = Color("OkGreen")
    static let info = Color("InfoBlue")

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 14
        static let lg: CGFloat = 20
    }
}

/// A reusable card container with consistent surface styling.
struct CardModifier: ViewModifier {
    var padding: CGFloat = Theme.Spacing.lg
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 0.5)
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = Theme.Spacing.lg) -> some View {
        modifier(CardModifier(padding: padding))
    }
}
