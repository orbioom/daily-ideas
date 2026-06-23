import SwiftUI

/// Centralized color + typography + spacing tokens for Ember.
/// All colors resolve from the asset catalog so light/dark both work.
enum Theme {
    // Surfaces
    static let bgPrimary = Color("BackgroundPrimary")
    static let bgSecondary = Color("BackgroundSecondary")
    static let card = Color("CardSurface")

    // Text
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")

    // Brand / accents
    static let accent = Color("AccentColor")
    static let emberWarm = Color("EmberWarm")
    static let emberGlow = Color("EmberGlow")
    static let calmTeal = Color("CalmTeal")
    static let deepBlue = Color("DeepBlue")
    static let energyCoral = Color("EnergyCoral")

    // Semantic
    static let good = Color("GoodGreen")
    static let warn = Color("WarnAmber")
    static let bad = Color("BadRose")

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 18
        static let lg: CGFloat = 28
    }
}

/// A reusable rounded card container with consistent surface styling.
struct CardBackground: ViewModifier {
    var padding: CGFloat = Theme.Spacing.md
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .strokeBorder(Theme.textSecondary.opacity(0.10), lineWidth: 1)
            )
    }
}

extension View {
    func emberCard(padding: CGFloat = Theme.Spacing.md) -> some View {
        modifier(CardBackground(padding: padding))
    }

    /// Screen background that always fills and respects safe areas.
    func emberScreenBackground() -> some View {
        background(Theme.bgPrimary.ignoresSafeArea())
    }
}
