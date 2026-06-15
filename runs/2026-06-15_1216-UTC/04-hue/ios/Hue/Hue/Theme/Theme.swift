import SwiftUI

// MARK: - Color helpers

extension Color {
    /// Build a color from a 24-bit RGB hex value (e.g. 0xC04CC8).
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    /// A dynamic color that resolves differently in light vs dark mode.
    static func dyn(_ light: UInt, _ dark: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((h >> 16) & 0xFF) / 255,
                green: CGFloat((h >> 8) & 0xFF) / 255,
                blue: CGFloat(h & 0xFF) / 255,
                alpha: 1
            )
        })
    }

    /// A six-digit uppercase hex string (without leading #). Used to persist fills.
    var hexString: String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return "FFFFFF" }
        let ri = Int((r * 255).rounded())
        let gi = Int((g * 255).rounded())
        let bi = Int((b * 255).rounded())
        return String(format: "%02X%02X%02X",
                      min(max(ri, 0), 255),
                      min(max(gi, 0), 255),
                      min(max(bi, 0), 255))
    }

    /// Parse a six-digit hex string (with or without leading #) into a Color.
    /// Returns nil for malformed input so callers can fall back gracefully.
    init?(hexString raw: String) {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = UInt(s, radix: 16) else { return nil }
        self.init(hex: value)
    }
}

// MARK: - Semantic design tokens

enum Theme {
    // Calm, gallery-like surfaces. Light = warm paper; dark = deep charcoal.
    static let bg = Color.dyn(0xF7F4F8, 0x121013)
    static let surface = Color.dyn(0xFFFFFF, 0x1E1A20)
    static let surfaceAlt = Color.dyn(0xF1EAF2, 0x272230)
    static let ink = Color.dyn(0x241F28, 0xF3EEF5)
    static let inkSoft = Color.dyn(0x5A5160, 0xC6BCCB)
    static let inkFaint = Color.dyn(0x9A8FA1, 0x7E7387)
    static let accent = Color(hex: 0xC04CC8)
    static let accentSoft = Color.dyn(0xF3DFF5, 0x3A2A40)
    static let hairline = Color.dyn(0xE6DCEA, 0x352E3C)
    static let good = Color.dyn(0x3FA66A, 0x5FD08C)
    static let warn = Color.dyn(0xC9911F, 0xE6B84A)
    static let bad = Color.dyn(0xC0445C, 0xE07089)

    // The neutral "unfilled" region color shown on a coloring page.
    static let regionUnfilled = Color(hex: 0xFFFFFF)
    static let regionStroke = Color(hex: 0x2A2530)

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static let corner: CGFloat = 18
    static let cornerSmall: CGFloat = 12
}

// MARK: - Reusable card surface

struct CardBackground: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func cardSurface(padding: CGFloat = 16) -> some View {
        modifier(CardBackground(padding: padding))
    }
}
