import SwiftUI

// MARK: - Color helpers

extension Color {
    /// Build a color from a 6-digit hex string (e.g. "3B5BA9"). Falls back to gray on bad input.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")).uppercased()
        var value: UInt64 = 0
        guard cleaned.count == 6, Scanner(string: cleaned).scanHexInt64(&value) else {
            self = Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5, opacity: 1)
            return
        }
        let r = Double((value & 0xFF0000) >> 16) / 255.0
        let g = Double((value & 0x00FF00) >> 8) / 255.0
        let b = Double(value & 0x0000FF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    /// Dynamic color that resolves to `light` in light mode and `dark` in dark mode.
    static func dyn(_ light: Color, _ dark: Color) -> Color {
        Color(UIColor { traits in
            let resolved = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(resolved)
        })
    }
}

// MARK: - Theme tokens

enum Theme {
    // Accent (deep blue paper-and-ink identity)
    static let accent = Color(hex: "3B5BA9")
    static let accentSoft = Color.dyn(Color(hex: "5B79C4"), Color(hex: "6E8AD4"))
    static let accentDeep = Color.dyn(Color(hex: "2C447E"), Color(hex: "8DA4E0"))

    // Surfaces
    static let background = Color.dyn(Color(hex: "F7F8FB"), Color(hex: "0E1116"))
    static let surface = Color.dyn(Color(hex: "FFFFFF"), Color(hex: "171B22"))
    static let surfaceRaised = Color.dyn(Color(hex: "FFFFFF"), Color(hex: "1E232C"))
    static let separator = Color.dyn(Color(hex: "E2E6EF"), Color(hex: "2A303A"))

    // Text (high contrast for AA)
    static let textPrimary = Color.dyn(Color(hex: "10141C"), Color(hex: "F2F4F8"))
    static let textSecondary = Color.dyn(Color(hex: "5A6373"), Color(hex: "9AA3B2"))
    static let textGiven = Color.dyn(Color(hex: "10141C"), Color(hex: "F2F4F8"))
    static let textEntry = Color.dyn(Color(hex: "2C447E"), Color(hex: "8DA4E0"))

    // Board states
    static let boardLine = Color.dyn(Color(hex: "C7CDDA"), Color(hex: "39414E"))
    static let boardLineBold = Color.dyn(Color(hex: "10141C"), Color(hex: "C9D1DE"))
    static let cellSelected = Color.dyn(Color(hex: "C9D6F2"), Color(hex: "2C3A5C"))
    static let cellPeer = Color.dyn(Color(hex: "E8EDF8"), Color(hex: "20283A"))
    static let cellSameNumber = Color.dyn(Color(hex: "D3DEF6"), Color(hex: "33405E"))
    static let cellConflict = Color.dyn(Color(hex: "F6D2D2"), Color(hex: "4A2A2E"))

    // Semantic
    static let success = Color.dyn(Color(hex: "1F8A4C"), Color(hex: "47C77E"))
    static let error = Color.dyn(Color(hex: "C03434"), Color(hex: "E8736F"))
    static let warning = Color.dyn(Color(hex: "B7791F"), Color(hex: "E0B24A"))

    // Fonts
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    // Layout
    static let corner: CGFloat = 16
    static let cornerSmall: CGFloat = 10
}
