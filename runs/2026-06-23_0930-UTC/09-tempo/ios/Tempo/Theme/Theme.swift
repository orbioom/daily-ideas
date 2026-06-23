import SwiftUI

/// Centralized design tokens for Tempo. Colors resolve from the asset catalog so
/// they adapt to light/dark automatically and meet WCAG AA contrast in both modes.
enum Theme {
    // Surfaces
    static let background = Color("AppBackground")
    static let card = Color("CardBackground")
    static let cardStroke = Color("CardStroke")

    // Text
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")

    // Brand & semantic
    static let accent = Color("AccentColor")
    static let pr = Color("PRGold")
    static let success = Color("SuccessGreen")
    static let rest = Color("RestBlue")
    static let coral = Color("WarmCoral")
    static let volume = Color("VolumePurple")

    enum Metrics {
        static let corner: CGFloat = 18
        static let cardPadding: CGFloat = 16
        static let spacing: CGFloat = 14
    }
}

/// A reusable elevated card surface used across the app for a cohesive identity.
struct CardModifier: ViewModifier {
    var padding: CGFloat = Theme.Metrics.cardPadding
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.corner, style: .continuous)
                    .strokeBorder(Theme.cardStroke, lineWidth: 1)
            )
    }
}

extension View {
    func cardSurface(padding: CGFloat = Theme.Metrics.cardPadding) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

/// Section header styling shared by feature screens.
struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.bold))
            .tracking(0.8)
            .foregroundStyle(Theme.textSecondary)
            .accessibilityAddTraits(.isHeader)
    }
}
