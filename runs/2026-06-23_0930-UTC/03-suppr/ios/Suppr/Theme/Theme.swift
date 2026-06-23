import SwiftUI

/// Central design tokens for Suppr. Colors resolve from the asset catalog so
/// light and dark mode are first-class everywhere.
enum Theme {
    // Surfaces
    static let background = Color("AppBackground")
    static let card = Color("CardBackground")
    static let hairline = Color("Hairline")

    // Text
    static let primaryText = Color("PrimaryText")
    static let secondaryText = Color("SecondaryText")

    // Brand
    static let terracotta = Color("BrandTerracotta")
    static let amber = Color("BrandAmber")
    static let sage = Color("BrandSage")

    // Layout
    static let corner: CGFloat = 18
    static let cardCorner: CGFloat = 22
    static let spacing: CGFloat = 16
}

extension View {
    /// Standard padded card surface used throughout the app.
    func cardSurface(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .fill(Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
    }
}
