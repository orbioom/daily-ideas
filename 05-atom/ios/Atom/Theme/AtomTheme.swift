import SwiftUI

enum AtomTheme {
    // Backgrounds
    static let background      = Color(red: 0.06, green: 0.06, blue: 0.10)
    static let cardBackground  = Color(red: 0.12, green: 0.12, blue: 0.18)
    static let surfaceAlt      = Color(red: 0.16, green: 0.16, blue: 0.24)

    // Accent
    static let accent          = Color(red: 0.30, green: 0.60, blue: 1.00)
    static let accentSecondary = Color(red: 0.20, green: 0.45, blue: 0.85)

    // Text
    static let textPrimary     = Color.white
    static let textSecondary   = Color(white: 0.65)
    static let textTertiary    = Color(white: 0.45)

    // Status
    static let success         = Color(red: 0.20, green: 0.80, blue: 0.45)
    static let error           = Color(red: 0.95, green: 0.30, blue: 0.30)
    static let warning         = Color(red: 0.95, green: 0.75, blue: 0.20)

    // Cell border
    static let cellBorder      = Color.white.opacity(0.15)

    // Corner radius
    static let cornerRadius: CGFloat    = 10
    static let cellCornerRadius: CGFloat = 4
}

// MARK: - View modifiers

struct AtomCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AtomTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AtomTheme.cornerRadius))
    }
}

struct AtomButtonStyle: ButtonStyle {
    var filled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(filled ? AtomTheme.textPrimary : AtomTheme.accent)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(filled ? AtomTheme.accent : AtomTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func atomCard() -> some View {
        modifier(AtomCardStyle())
    }
}
