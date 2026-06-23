import SwiftUI

/// Central design tokens for Petal. All colors are asset-catalog backed so they
/// adapt to light/dark mode automatically.
enum Theme {
    // Surfaces
    static let background = Color("AppBackground")
    static let card = Color("CardBackground")
    static let divider = Color("Divider")

    // Text
    static let primaryText = Color("PrimaryText")
    static let secondaryText = Color("SecondaryText")

    // Accents
    static let accent = Color("AccentColor")
    static let pink = Color("AccentPink")
    static let amber = Color("AccentAmber")
    static let blue = Color("AccentBlue")
    static let lilac = Color("AccentLilac")

    // Semantic
    static let danger = Color("DangerColor")
    static let success = Color("SuccessColor")

    enum Metrics {
        static let corner: CGFloat = 18
        static let cardPadding: CGFloat = 16
        static let spacing: CGFloat = 14
    }
}

/// Card container used throughout the app for a cohesive look.
struct PetalCard<Content: View>: View {
    var content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    var body: some View {
        content()
            .padding(Theme.Metrics.cardPadding)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.corner, style: .continuous)
                    .strokeBorder(Theme.divider, lineWidth: 1)
            )
    }
}

extension View {
    /// Applies the standard screen background, ignoring safe areas.
    func petalScreenBackground() -> some View {
        self.background(Theme.background.ignoresSafeArea())
    }
}
