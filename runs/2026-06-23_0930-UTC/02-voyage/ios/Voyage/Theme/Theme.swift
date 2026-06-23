import SwiftUI

/// Central design tokens for Voyage. All colors come from the asset catalog so
/// light and dark mode are first-class. Spacing / radii / typography are unified here.
enum Theme {
    // MARK: Colors
    static let background = Color("AppBackground")
    static let card = Color("CardBackground")
    static let surface2 = Color("Surface2")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let brand = Color("BrandPrimary")
    static let brandDeep = Color("BrandDeep")
    static let success = Color("SuccessColor")
    static let warn = Color("WarnColor")

    // MARK: Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: Radii
    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 22
        static let pill: CGFloat = 999
    }

    /// Brand gradient used on hero surfaces.
    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [brandDeep, brand],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Reusable view styling

/// A standard rounded card surface.
struct CardSurface: ViewModifier {
    var padding: CGFloat = Theme.Spacing.lg
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .strokeBorder(Theme.textSecondary.opacity(0.12), lineWidth: 1)
            )
    }
}

extension View {
    func cardSurface(padding: CGFloat = Theme.Spacing.lg) -> some View {
        modifier(CardSurface(padding: padding))
    }
}

/// Primary filled button look.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md + 2)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(isEnabled ? Theme.brand : Theme.textSecondary.opacity(0.4))
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Secondary outlined button.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.brand)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md + 2)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .strokeBorder(Theme.brand, lineWidth: 1.5)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
