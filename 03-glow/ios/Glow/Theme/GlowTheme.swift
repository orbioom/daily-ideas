import SwiftUI

enum GlowTheme {
    // MARK: - Colors

    static let primary = Color("GlowPrimary")       // #E8A0B4 soft rose
    static let accent = Color("GlowAccent")         // #C76B90 deeper rose
    static let background = Color("GlowBackground") // white/light rose
    static let textPrimary = Color("GlowText")      // #1A1A2E dark navy

    static let rating1 = Color(red: 0.18, green: 0.72, blue: 0.45)   // green
    static let rating2 = Color(red: 0.55, green: 0.82, blue: 0.28)   // light green
    static let rating3 = Color(red: 0.99, green: 0.78, blue: 0.12)   // yellow
    static let rating4 = Color(red: 0.98, green: 0.53, blue: 0.15)   // orange
    static let rating5 = Color(red: 0.90, green: 0.22, blue: 0.22)   // red

    static func ratingColor(_ rating: Int) -> Color {
        switch rating {
        case 1: return rating1
        case 2: return rating2
        case 3: return rating3
        case 4: return rating4
        case 5: return rating5
        default: return .gray
        }
    }

    static func ratingLabel(_ rating: Int) -> String {
        switch rating {
        case 1: return "Clean"
        case 2: return "Good"
        case 3: return "Moderate"
        case 4: return "Caution"
        case 5: return "Avoid"
        default: return "Unknown"
        }
    }

    // MARK: - Typography

    static let headlineFont = Font.system(.title2, design: .rounded, weight: .bold)
    static let titleFont = Font.system(.title3, design: .rounded, weight: .semibold)
    static let bodyFont = Font.system(.body, design: .rounded)
    static let captionFont = Font.system(.caption, design: .rounded)
    static let labelFont = Font.system(.callout, design: .rounded, weight: .medium)

    // MARK: - Dimensions

    static let cardCornerRadius: CGFloat = 16
    static let chipCornerRadius: CGFloat = 10
    static let badgeCornerRadius: CGFloat = 8
    static let horizontalPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let smallSpacing: CGFloat = 8
    static let mediumSpacing: CGFloat = 12
    static let largeSpacing: CGFloat = 20
}

// MARK: - View Modifiers

struct GlowCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: GlowTheme.cardCornerRadius))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func glowCard() -> some View {
        modifier(GlowCard())
    }
}
