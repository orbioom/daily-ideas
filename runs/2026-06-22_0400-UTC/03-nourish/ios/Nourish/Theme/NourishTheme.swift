import SwiftUI

// MARK: - NourishTheme (flat namespace for easy access)

enum NourishTheme {
    // MARK: - Colors (flat accessors matching linter-revised files)
    static let sage = Color(red: 0.290, green: 0.486, blue: 0.349)
    static let background = Color(red: 0.980, green: 0.969, blue: 0.949)
    static let terra = Color(red: 0.831, green: 0.522, blue: 0.416)
    static let charcoal = Color(red: 0.173, green: 0.141, blue: 0.086)
    static let corn = Color(red: 0.929, green: 0.773, blue: 0.243)
    static let card = Color(red: 1.0, green: 0.996, blue: 0.988)
    static let secondaryText = Color(red: 0.173, green: 0.141, blue: 0.086).opacity(0.55)
    static let divider = Color(red: 0.173, green: 0.141, blue: 0.086).opacity(0.1)
    static let sageMuted = Color(red: 0.290, green: 0.486, blue: 0.349).opacity(0.12)
    static let terraMuted = Color(red: 0.831, green: 0.522, blue: 0.416).opacity(0.15)
    static let safeGreen = Color(red: 0.290, green: 0.486, blue: 0.349)

    // MARK: - Nested Colors namespace (for legacy references)
    enum Colors {
        static let accent = NourishTheme.sage
        static let background = NourishTheme.background
        static let terra = NourishTheme.terra
        static let text = NourishTheme.charcoal
        static let sage = NourishTheme.sage
        static let sageMuted = NourishTheme.sageMuted
        static let terraMuted = NourishTheme.terraMuted
        static let cardBackground = NourishTheme.card
        static let divider = NourishTheme.divider
        static let secondaryText = NourishTheme.secondaryText
        static let safeColor = NourishTheme.safeGreen
        static let cornColor = NourishTheme.corn

        // Allergen category colors
        static let glutenColor = Color(red: 0.784, green: 0.620, blue: 0.404)
        static let dairyColor = Color(red: 0.580, green: 0.737, blue: 0.820)
        static let eggColor = Color(red: 0.949, green: 0.816, blue: 0.369)
        static let nutsColor = Color(red: 0.620, green: 0.447, blue: 0.255)
        static let soyColor = Color(red: 0.486, green: 0.624, blue: 0.388)
        static let cornColor2 = Color(red: 0.929, green: 0.773, blue: 0.243)
        static let nightshadeColor = Color(red: 0.627, green: 0.404, blue: 0.655)
        static let fodmapColor = Color(red: 0.408, green: 0.608, blue: 0.584)

        static func allergenColor(for category: String) -> Color {
            NourishTheme.allergenColor(for: category)
        }
    }

    // MARK: - Allergen Colors (shared function)
    static func allergenColor(for category: String) -> Color {
        switch category.lowercased() {
        case "gluten": return Color(red: 0.784, green: 0.620, blue: 0.404)
        case "dairy": return Color(red: 0.580, green: 0.737, blue: 0.820)
        case "eggs": return Color(red: 0.949, green: 0.816, blue: 0.369)
        case "nuts": return Color(red: 0.620, green: 0.447, blue: 0.255)
        case "soy": return Color(red: 0.486, green: 0.624, blue: 0.388)
        case "corn": return Color(red: 0.929, green: 0.773, blue: 0.243)
        case "nightshades": return Color(red: 0.627, green: 0.404, blue: 0.655)
        case "low-fodmap": return Color(red: 0.408, green: 0.608, blue: 0.584)
        case "safe", "neutral": return NourishTheme.sage
        default: return NourishTheme.sage
        }
    }

    // MARK: - Typography
    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 16, weight: .regular, design: .rounded)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .rounded)
        static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .rounded)
    }

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius
    enum CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let pill: CGFloat = 999
    }

    // MARK: - Shadow
    enum Shadow {
        static let card = (color: Color.black.opacity(0.06), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(2))
        static let button = (color: Color.black.opacity(0.12), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
    }
}

// MARK: - View Modifiers

struct NourishCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(NourishTheme.card)
            .cornerRadius(NourishTheme.CornerRadius.lg)
            .shadow(
                color: NourishTheme.Shadow.card.color,
                radius: NourishTheme.Shadow.card.radius,
                x: NourishTheme.Shadow.card.x,
                y: NourishTheme.Shadow.card.y
            )
    }
}

struct PrimaryButton: ViewModifier {
    var isDestructive: Bool = false

    func body(content: Content) -> some View {
        content
            .font(NourishTheme.Typography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, NourishTheme.Spacing.md)
            .background(isDestructive ? NourishTheme.terra : NourishTheme.sage)
            .cornerRadius(NourishTheme.CornerRadius.md)
    }
}

extension View {
    func nourishCard() -> some View {
        modifier(NourishCard())
    }

    func primaryButton(isDestructive: Bool = false) -> some View {
        modifier(PrimaryButton(isDestructive: isDestructive))
    }
}

// MARK: - Color Extensions (for components that use NourishTheme.Colors.*)

extension NourishTheme.Colors {
    // Expose top-level static vars through Colors namespace too
    static let safeGreen = NourishTheme.safeGreen
}
