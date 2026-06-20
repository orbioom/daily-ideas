import SwiftUI

enum DojoTheme {
    // MARK: - Background Colors
    static let darkBg = Color(red: 0.07, green: 0.07, blue: 0.09)
    static let cardBg = Color(red: 0.12, green: 0.12, blue: 0.15)
    static let elevatedBg = Color(red: 0.16, green: 0.16, blue: 0.20)

    // MARK: - Accent Colors
    static let crimson = Color(red: 0.75, green: 0.10, blue: 0.12)
    static let crimsonBright = Color(red: 0.85, green: 0.15, blue: 0.17)
    static let gold = Color(red: 0.85, green: 0.70, blue: 0.25)

    // MARK: - Text Colors
    static let primaryText = Color.white
    static let subtleText = Color.white.opacity(0.5)
    static let tertiaryText = Color.white.opacity(0.3)

    // MARK: - Belt Colors
    static let beltWhite = Color(red: 0.92, green: 0.92, blue: 0.92)
    static let beltBlue = Color(red: 0.20, green: 0.40, blue: 0.80)
    static let beltPurple = Color(red: 0.50, green: 0.15, blue: 0.65)
    static let beltBrown = Color(red: 0.45, green: 0.28, blue: 0.12)
    static let beltBlack = Color(red: 0.10, green: 0.10, blue: 0.10)

    static func beltColor(_ belt: BjjBelt) -> Color {
        switch belt {
        case .white: return beltWhite
        case .blue: return beltBlue
        case .purple: return beltPurple
        case .brown: return beltBrown
        case .black: return beltBlack
        }
    }

    static func beltTextColor(_ belt: BjjBelt) -> Color {
        switch belt {
        case .white: return .black
        case .black: return .white
        default: return .white
        }
    }

    // MARK: - Gradient
    static let crimsonGradient = LinearGradient(
        colors: [crimson, crimson.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let darkGradient = LinearGradient(
        colors: [darkBg, cardBg],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DojoTheme.cardBg)
            .cornerRadius(12)
    }
}

struct CrimsonButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                configuration.isPressed
                    ? DojoTheme.crimson.opacity(0.7)
                    : DojoTheme.crimson
            )
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
