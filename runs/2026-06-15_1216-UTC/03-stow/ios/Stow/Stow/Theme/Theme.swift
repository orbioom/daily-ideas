import SwiftUI

// MARK: - Color helpers

extension Color {
    /// Build a Color from a 24-bit hex value, e.g. 0xC86B3C.
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    /// A dynamic color that resolves differently per interface style.
    static func dyn(_ l: UInt, _ d: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? d : l
            return UIColor(
                red: CGFloat((h >> 16) & 0xFF) / 255,
                green: CGFloat((h >> 8) & 0xFF) / 255,
                blue: CGFloat(h & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

// MARK: - Theme tokens (warm "reading nook" — paper / sepia)

enum Theme {
    // Backgrounds
    static let bg        = Color.dyn(0xF6F1EA, 0x14110D)
    static let surface   = Color.dyn(0xFFFDF9, 0x1F1A14)
    static let surfaceAlt = Color.dyn(0xEFE7DC, 0x282119)

    // Ink (text)
    static let ink       = Color.dyn(0x2B2419, 0xF1E9DC)
    static let inkSoft   = Color.dyn(0x6B5E4C, 0xC4B5A0)
    static let inkFaint  = Color.dyn(0x9C8E78, 0x80715C)

    // Accent (rust / amber)
    static let accent    = Color.dyn(0xC86B3C, 0xDB8050)
    static let accentSoft = Color.dyn(0xF3E0D2, 0x3A2A1D)

    // Lines & status
    static let hairline  = Color.dyn(0xE3D9CA, 0x352C22)
    static let good      = Color.dyn(0x4F7A4C, 0x8FBF89)
    static let warn      = Color.dyn(0xB7892E, 0xE0B860)
    static let bad       = Color.dyn(0xB0473A, 0xE08070)

    // Corners
    static let corner: CGFloat = 18
    static let cornerSmall: CGFloat = 12

    // Fonts
    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }
    static func serif(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .serif)
    }
    static func mono(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .monospaced)
    }
}

// MARK: - Reusable view modifiers

struct CardSurface: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func cardSurface(padding: CGFloat = 16) -> some View {
        modifier(CardSurface(padding: padding))
    }
}
