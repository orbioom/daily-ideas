import SwiftUI

// MARK: - Gammon Theme
// Classic backgammon aesthetic: mahogany wood tones, ivory pieces, warm amber accents.

enum BoardColorScheme: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case emerald = "Emerald"
    case midnight = "Midnight"
    case burgundy = "Burgundy"

    var id: String { rawValue }

    var pointColorA: Color {
        switch self {
        case .classic:  return Color(red: 0.78, green: 0.22, blue: 0.12)   // deep red
        case .emerald:  return Color(red: 0.13, green: 0.55, blue: 0.30)   // forest green
        case .midnight: return Color(red: 0.15, green: 0.25, blue: 0.60)   // navy
        case .burgundy: return Color(red: 0.55, green: 0.08, blue: 0.22)   // burgundy
        }
    }

    var pointColorB: Color {
        switch self {
        case .classic:  return Color(red: 0.93, green: 0.87, blue: 0.68)   // ivory
        case .emerald:  return Color(red: 0.88, green: 0.80, blue: 0.55)   // golden
        case .midnight: return Color(red: 0.78, green: 0.82, blue: 0.95)   // pale blue
        case .burgundy: return Color(red: 0.90, green: 0.75, blue: 0.50)   // warm cream
        }
    }

    var boardSurface: Color {
        switch self {
        case .classic:  return Color(red: 0.25, green: 0.14, blue: 0.06)   // dark mahogany
        case .emerald:  return Color(red: 0.08, green: 0.20, blue: 0.12)   // deep green
        case .midnight: return Color(red: 0.06, green: 0.08, blue: 0.20)   // deep navy
        case .burgundy: return Color(red: 0.20, green: 0.06, blue: 0.10)   // deep burgundy
        }
    }

    var boardBorder: Color {
        switch self {
        case .classic:  return Color(red: 0.38, green: 0.20, blue: 0.06)   // lighter mahogany
        case .emerald:  return Color(red: 0.15, green: 0.35, blue: 0.18)
        case .midnight: return Color(red: 0.12, green: 0.15, blue: 0.35)
        case .burgundy: return Color(red: 0.35, green: 0.10, blue: 0.18)
        }
    }
}

struct GammonTheme {
    // MARK: - Colors

    static let accent        = Color(red: 0.831, green: 0.627, blue: 0.125)  // warm amber #D4A020
    static let accentLight   = Color(red: 0.92, green: 0.76, blue: 0.35)
    static let accentDark    = Color(red: 0.55, green: 0.38, blue: 0.05)

    static let background    = Color(red: 0.10, green: 0.05, blue: 0.02)     // very dark brown
    static let surface       = Color(red: 0.16, green: 0.09, blue: 0.04)     // card surface
    static let surfaceHigh   = Color(red: 0.22, green: 0.13, blue: 0.06)     // elevated surface

    static let textPrimary   = Color(red: 0.95, green: 0.90, blue: 0.80)     // warm white
    static let textSecondary = Color(red: 0.65, green: 0.57, blue: 0.44)     // muted warm
    static let textMuted     = Color(red: 0.40, green: 0.33, blue: 0.24)

    static let whitePiece    = Color(red: 0.95, green: 0.92, blue: 0.84)     // cream/ivory
    static let blackPiece    = Color(red: 0.14, green: 0.10, blue: 0.07)     // near-black
    static let whitePieceShadow = Color(red: 0.70, green: 0.62, blue: 0.48)
    static let blackPieceShadow = Color(red: 0.02, green: 0.01, blue: 0.00)

    static let highlightRing = Color(red: 1.0, green: 0.85, blue: 0.20)      // bright gold
    static let legalDot      = Color(red: 0.40, green: 0.90, blue: 0.40).opacity(0.75)
    static let barColor      = Color(red: 0.30, green: 0.16, blue: 0.06)

    static let winColor      = Color(red: 0.20, green: 0.75, blue: 0.35)
    static let loseColor     = Color(red: 0.80, green: 0.20, blue: 0.20)

    // MARK: - Typography

    static let titleFont     = Font.system(.largeTitle, design: .serif, weight: .bold)
    static let headingFont   = Font.system(.title2,    design: .serif, weight: .semibold)
    static let bodyFont      = Font.system(.body,      design: .rounded)
    static let captionFont   = Font.system(.caption,   design: .rounded)
    static let monoFont      = Font.system(.callout,   design: .monospaced, weight: .medium)

    // MARK: - Spacing

    static let cornerRadius: CGFloat = 12
    static let cardPadding: CGFloat  = 16
    static let sectionSpacing: CGFloat = 24
}

// MARK: - View Modifiers

extension View {
    func gammonCard() -> some View {
        self
            .background(GammonTheme.surface)
            .cornerRadius(GammonTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: GammonTheme.cornerRadius)
                    .stroke(GammonTheme.accentDark.opacity(0.5), lineWidth: 1)
            )
    }

    func gammonButton(large: Bool = false) -> some View {
        self
            .font(large ? .headline : .subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(GammonTheme.background)
            .padding(.horizontal, large ? 32 : 20)
            .padding(.vertical, large ? 14 : 10)
            .background(GammonTheme.accent)
            .cornerRadius(large ? 14 : 10)
            .shadow(color: GammonTheme.accent.opacity(0.4), radius: 8, y: 3)
    }
}
