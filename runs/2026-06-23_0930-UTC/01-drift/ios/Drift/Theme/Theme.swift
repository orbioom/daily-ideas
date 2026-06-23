import SwiftUI

/// Central color + style tokens. Every color references an asset-catalog color set
/// so light and dark mode are both first-class and WCAG-AA friendly.
enum Theme {
    // Surfaces
    static let backgroundPrimary = Color("BackgroundPrimary")
    static let backgroundSecondary = Color("BackgroundSecondary")
    static let card = Color("CardSurface")

    // Text
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")

    // Brand / semantic
    static let night = Color("NightBlue")
    static let dusk = Color("DuskViolet")
    static let dawn = Color("DawnPeach")
    static let good = Color("GoodGreen")
    static let warn = Color("WarnAmber")
    static let bad = Color("BadRose")

    static let accent = Color("AccentColor")

    /// Soft dusk → night gradient used on hero surfaces.
    static var nightGradient: LinearGradient {
        LinearGradient(
            colors: [dusk.opacity(0.9), night.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static let corner: CGFloat = 18
    static let cardShadow = Color.black.opacity(0.08)
}

extension View {
    /// Standard card container used across the app.
    func driftCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
            .shadow(color: Theme.cardShadow, radius: 10, x: 0, y: 4)
    }
}
