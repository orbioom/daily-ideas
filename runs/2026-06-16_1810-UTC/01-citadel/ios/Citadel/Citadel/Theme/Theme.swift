import SwiftUI

/// The felt color options the player can pick in Settings. Each provides a calm,
/// AA-contrast-safe baize for both light and dark mode.
enum FeltStyle: String, CaseIterable, Identifiable, Codable {
    case emerald   // default — classic casino green
    case sapphire  // Pro
    case burgundy  // Pro
    case slate     // Pro

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .emerald: return "Emerald"
        case .sapphire: return "Sapphire"
        case .burgundy: return "Burgundy"
        case .slate: return "Slate"
        }
    }

    /// Whether this style requires Citadel Pro.
    var requiresPro: Bool { self != .emerald }

    /// Deep felt color for dark mode (near-black, tinted).
    func darkFelt() -> Color {
        switch self {
        case .emerald:  return Color(red: 0.03, green: 0.10, blue: 0.07)
        case .sapphire: return Color(red: 0.03, green: 0.06, blue: 0.13)
        case .burgundy: return Color(red: 0.10, green: 0.03, blue: 0.05)
        case .slate:    return Color(red: 0.07, green: 0.08, blue: 0.10)
        }
    }

    /// Soft felt color for light mode (gentle, desaturated).
    func lightFelt() -> Color {
        switch self {
        case .emerald:  return Color(red: 0.80, green: 0.87, blue: 0.81)
        case .sapphire: return Color(red: 0.80, green: 0.84, blue: 0.91)
        case .burgundy: return Color(red: 0.90, green: 0.82, blue: 0.83)
        case .slate:    return Color(red: 0.85, green: 0.86, blue: 0.88)
        }
    }
}

/// Central design tokens. Resolves felt by color scheme; everything else uses
/// semantic system colors so contrast stays AA-correct in both modes.
struct Theme {
    var felt: FeltStyle = .emerald

    /// The signature accent — matches the AccentColor asset (#1E8E5A).
    static let accent = Color(red: 0x1E / 255, green: 0x8E / 255, blue: 0x5A / 255)

    /// A quiet warm gold used for highlights (won streaks, selection ring, Pro flair).
    static let gold = Color(red: 0.83, green: 0.68, blue: 0.34)

    /// Resolve the felt background for a given color scheme.
    func feltColor(for scheme: ColorScheme) -> Color {
        scheme == .dark ? felt.darkFelt() : felt.lightFelt()
    }

    /// A subtle felt gradient for depth (very low contrast variation).
    func feltGradient(for scheme: ColorScheme) -> LinearGradient {
        let base = feltColor(for: scheme)
        let edge = scheme == .dark ? base.opacity(0.85) : base.opacity(0.92)
        return LinearGradient(
            colors: [base, edge],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Card surface

    /// Warm ivory card face. Works in both modes (cards are always light by design).
    static let cardFace = Color(red: 0.98, green: 0.97, blue: 0.93)
    /// Card face when selected/lifted.
    static let cardFaceRaised = Color(red: 1.0, green: 0.99, blue: 0.96)
    /// Empty slot border on the felt.
    static func slotStroke(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.18) : Color.black.opacity(0.18)
    }
    static func slotFill(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black.opacity(0.20) : Color.black.opacity(0.06)
    }

    /// Red pip and black pip colors (crisp on ivory).
    static let redPip = Color(red: 0.72, green: 0.12, blue: 0.13)
    static let blackPip = Color(red: 0.10, green: 0.11, blue: 0.13)

    /// Foreground text that reads on the felt in both modes.
    static func feltText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.94) : Color(red: 0.10, green: 0.16, blue: 0.12)
    }
    static func feltTextSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.72) : Color(red: 0.22, green: 0.30, blue: 0.25)
    }
}

/// Environment key so the resolved Theme flows down the view tree.
private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme()
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
