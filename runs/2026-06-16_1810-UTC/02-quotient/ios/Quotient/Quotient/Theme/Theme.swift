import SwiftUI

/// Centralized design tokens for Quotient. Every color resolves correctly in
/// both light and dark mode and meets WCAG AA contrast. The accent (#6C5CE7)
/// comes from the asset catalog so it stays in sync with the global tint.
enum Theme {
    // MARK: Brand

    static let accent = Color("AccentColor")
    static let accentHex = "#6C5CE7"

    // MARK: Surfaces (adaptive light/dark)

    /// App background — a soft neutral.
    static let background = Color(
        light: Color(red: 0.96, green: 0.96, blue: 0.98),
        dark: Color(red: 0.07, green: 0.07, blue: 0.10)
    )

    /// Card / panel surface raised above the background.
    static let surface = Color(
        light: .white,
        dark: Color(red: 0.13, green: 0.13, blue: 0.17)
    )

    /// A secondary surface, e.g. a number-pad key at rest.
    static let surfaceElevated = Color(
        light: Color(red: 0.99, green: 0.99, blue: 1.0),
        dark: Color(red: 0.17, green: 0.17, blue: 0.22)
    )

    /// The grid cell fill at rest.
    static let cellFill = Color(
        light: .white,
        dark: Color(red: 0.15, green: 0.15, blue: 0.19)
    )

    /// Row/column/cage highlight tint behind selected related cells.
    static let highlightSoft = Color(
        light: Color(red: 0.93, green: 0.92, blue: 0.99),
        dark: Color(red: 0.20, green: 0.18, blue: 0.30)
    )

    /// The currently selected cell fill.
    static var selection: Color { accent.opacity(0.22) }

    /// Conflict highlight (wrong / duplicate value).
    static let conflict = Color(
        light: Color(red: 0.86, green: 0.20, blue: 0.27),
        dark: Color(red: 1.0, green: 0.45, blue: 0.50)
    )

    static let conflictFill = Color(
        light: Color(red: 1.0, green: 0.92, blue: 0.93),
        dark: Color(red: 0.35, green: 0.16, blue: 0.18)
    )

    static let success = Color(
        light: Color(red: 0.10, green: 0.62, blue: 0.42),
        dark: Color(red: 0.30, green: 0.82, blue: 0.60)
    )

    // MARK: Lines

    /// Thick cage border.
    static let cageBorder = Color(
        light: Color(red: 0.18, green: 0.18, blue: 0.24),
        dark: Color(red: 0.78, green: 0.78, blue: 0.84)
    )

    /// Thin interior grid line.
    static let gridLine = Color(
        light: Color(red: 0.80, green: 0.80, blue: 0.84),
        dark: Color(red: 0.32, green: 0.32, blue: 0.38)
    )

    // MARK: Text

    static let textPrimary = Color(
        light: Color(red: 0.10, green: 0.10, blue: 0.14),
        dark: Color(red: 0.95, green: 0.95, blue: 0.98)
    )

    static let textSecondary = Color(
        light: Color(red: 0.42, green: 0.42, blue: 0.48),
        dark: Color(red: 0.66, green: 0.66, blue: 0.72)
    )

    // MARK: Metrics

    static let cornerRadius: CGFloat = 16
    static let cellCornerRadius: CGFloat = 6
    static let thinLine: CGFloat = 1
    static let thickLine: CGFloat = 3
}

extension Color {
    /// Resolves to `light` or `dark` based on the active interface style.
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

/// The accent palette choices a Pro user can pick (extra themes feature).
enum AccentTheme: String, CaseIterable, Identifiable {
    case indigo
    case teal
    case amber
    case rose

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .indigo: return "Indigo"
        case .teal:   return "Teal"
        case .amber:  return "Amber"
        case .rose:   return "Rose"
        }
    }

    /// The tint color. Indigo maps to the brand asset color.
    var color: Color {
        switch self {
        case .indigo: return Theme.accent
        case .teal:   return Color(red: 0.0, green: 0.65, blue: 0.62)
        case .amber:  return Color(red: 0.90, green: 0.58, blue: 0.10)
        case .rose:   return Color(red: 0.86, green: 0.24, blue: 0.45)
        }
    }

    var isPremium: Bool { self != .indigo }
}
