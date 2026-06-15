import SwiftUI
import UIKit

// MARK: - Color helpers

extension Color {
    /// Build a Color from a 24-bit RGB hex value (e.g. 0x4C63D8).
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    /// Resolve to a light or dark value based on the active trait collection.
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

extension UIColor {
    /// Build a UIColor from a 24-bit RGB hex value.
    convenience init(hex: UInt, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

extension UInt {
    /// Encode a 24-bit RGB value as a "#RRGGBB" string.
    var rgbHexString: String {
        let r = (self >> 16) & 0xFF
        let g = (self >> 8) & 0xFF
        let b = self & 0xFF
        return String(format: "#%02X%02X%02X", Int(r), Int(g), Int(b))
    }
}

extension Color {
    /// Parse a "#RRGGBB" string into a Color; falls back to the supplied default.
    init(hexString: String, fallback: UInt = 0x4C63D8) {
        let scrubbed = hexString.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        if let value = UInt(scrubbed, radix: 16), scrubbed.count == 6 {
            self.init(hex: value)
        } else {
            self.init(hex: fallback)
        }
    }
}

// MARK: - Theme tokens

/// Quill's calm "paper & ink" design language. Indigo accent over warm paper.
enum Theme {
    // Backgrounds
    static let bg = Color.dyn(0xF6F2EA, 0x141318)        // warm paper / near-black
    static let surface = Color.dyn(0xFFFFFF, 0x1F1E25)   // cards
    static let surfaceAlt = Color.dyn(0xEFE9DE, 0x26252E) // grouped fills

    // Ink (text)
    static let ink = Color.dyn(0x1E1B2E, 0xF3F1F8)
    static let inkSoft = Color.dyn(0x55506A, 0xB6B2C4)
    static let inkFaint = Color.dyn(0x8C879C, 0x726E80)

    // Accent — indigo
    static let accent = Color.dyn(0x4C63D8, 0x7C8CF0)
    static let accentSoft = Color.dyn(0xE3E6FB, 0x2C2E4A)

    // Lines & status
    static let hairline = Color.dyn(0xDED7C9, 0x33323C)
    static let good = Color.dyn(0x2E9E6B, 0x55C998)
    static let warn = Color.dyn(0xC9882B, 0xE2B463)
    static let bad = Color.dyn(0xC4453F, 0xE5736D)

    // Paper rendering colors for templates (lines on the page)
    static let paperLine = Color.dyn(0xC9D4E8, 0x3A3D4A)
    static let paperColor = Color.dyn(0xFFFFFF, 0x1B1A21)

    // Fonts
    static func rounded(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .rounded)
    }
    static func serif(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        .system(size: s, weight: w, design: .serif)
    }

    // Geometry
    static let corner: CGFloat = 18
    static let cornerSmall: CGFloat = 12
}

// MARK: - Cover color palette

/// Curated notebook cover colors. Base colors are free; the rest require Pro.
enum CoverPalette {
    /// Free-tier cover/ink colors.
    static let base: [UInt] = [0x4C63D8, 0x1E1B2E, 0xC4453F, 0x2E9E6B]

    /// Pro-only additional colors.
    static let pro: [UInt] = [
        0xE2731D, 0x8E44AD, 0x0EA5A4, 0xD81B60,
        0x5D4037, 0x37474F, 0xF2B705, 0x2C7BE5
    ]

    static var all: [UInt] { base + pro }

    /// Returns the colors available given the current Pro state.
    static func available(isPro: Bool) -> [UInt] {
        isPro ? all : base
    }
}
