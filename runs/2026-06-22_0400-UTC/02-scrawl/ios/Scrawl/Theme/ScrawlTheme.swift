import SwiftUI

enum ScrawlTheme {
    // MARK: - Colors
    static let cream = Color(red: 1.0, green: 254/255, blue: 245/255)
    static let charcoal = Color(red: 28/255, green: 28/255, blue: 30/255)
    static let skyBlue = Color(red: 74/255, green: 144/255, blue: 217/255)
    static let coral = Color(red: 255/255, green: 107/255, blue: 107/255)
    static let lightGray = Color(red: 242/255, green: 242/255, blue: 247/255)
    static let warmGray = Color(red: 200/255, green: 199/255, blue: 204/255)
    static let successGreen = Color(red: 52/255, green: 199/255, blue: 89/255)
    static let warningOrange = Color(red: 255/255, green: 149/255, blue: 0/255)

    // MARK: - Adaptive Colors
    static var background: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1)
                : UIColor(red: 1.0, green: 254/255, blue: 245/255, alpha: 1)
        })
    }

    static var cardBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 44/255, green: 44/255, blue: 46/255, alpha: 1)
                : UIColor.white
        })
    }

    static var primaryText: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white
                : UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1)
        })
    }

    static var secondaryText: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 0.7, alpha: 1)
                : UIColor(red: 100/255, green: 100/255, blue: 102/255, alpha: 1)
        })
    }

    // MARK: - Typography
    static func displayFont(size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func headlineFont(size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func bodyFont(size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    static func captionFont(size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    // MARK: - Spacing
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    static let paddingXLarge: CGFloat = 32

    // MARK: - Corner Radius
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 16
    static let cornerRadiusLarge: CGFloat = 24

    // MARK: - Shadow
    static func cardShadow() -> some View {
        Rectangle()
            .fill(Color.clear)
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - View Modifiers
extension View {
    func scrawlCard() -> some View {
        self
            .background(ScrawlTheme.cardBackground)
            .cornerRadius(ScrawlTheme.cornerRadiusMedium)
            .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 3)
    }

    func scrawlPrimaryButton() -> some View {
        self
            .font(ScrawlTheme.headlineFont())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(ScrawlTheme.skyBlue)
            .cornerRadius(ScrawlTheme.cornerRadiusMedium)
            .shadow(color: ScrawlTheme.skyBlue.opacity(0.35), radius: 8, x: 0, y: 4)
    }

    func scrawlSecondaryButton() -> some View {
        self
            .font(ScrawlTheme.headlineFont())
            .foregroundStyle(ScrawlTheme.skyBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(ScrawlTheme.skyBlue.opacity(0.12))
            .cornerRadius(ScrawlTheme.cornerRadiusMedium)
    }

    func scrawlDestructiveButton() -> some View {
        self
            .font(ScrawlTheme.headlineFont())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(ScrawlTheme.coral)
            .cornerRadius(ScrawlTheme.cornerRadiusMedium)
    }
}
