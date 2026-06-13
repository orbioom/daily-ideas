import SwiftUI
import UIKit

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255.0,
                  green: Double((hex >> 8) & 0xFF) / 255.0,
                  blue: Double(hex & 0xFF) / 255.0,
                  opacity: 1.0)
    }
    /// A color that resolves differently in light and dark mode.
    static func dyn(_ light: UInt, _ dark: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((h >> 16) & 0xFF) / 255.0,
                           green: CGFloat((h >> 8) & 0xFF) / 255.0,
                           blue: CGFloat(h & 0xFF) / 255.0,
                           alpha: 1.0)
        })
    }
}

/// Verso — an editorial, paper-and-ink visual identity.
enum Theme {
    static let bg        = Color.dyn(0xF3EEE2, 0x0E1311)   // warm paper / near-black
    static let surface   = Color.dyn(0xFBF8F1, 0x171C1A)   // raised card
    static let surfaceAlt = Color.dyn(0xEDE6D6, 0x1F2522)
    static let ink       = Color.dyn(0x1C1A16, 0xF1ECE0)   // primary text
    static let inkSoft   = Color.dyn(0x5C574C, 0xAFA89A)   // secondary text
    static let inkFaint  = Color.dyn(0x8A8273, 0x726C5F)
    static let accent    = Color.dyn(0x127467, 0x4FB7A6)   // teal
    static let accentSoft = Color.dyn(0xDCEDE9, 0x14302B)
    static let hairline  = Color.dyn(0xDDD6C6, 0x2A302D)
    static let amber     = Color.dyn(0xB9802B, 0xD8A24A)
    static let highlight = Color.dyn(0xF6E6B8, 0x3A3320)

    // Note color tags
    static let tagColors: [(name: String, light: UInt, dark: UInt)] = [
        ("None",   0x8A8273, 0x726C5F),
        ("Teal",   0x127467, 0x4FB7A6),
        ("Rust",   0xB4502E, 0xD9794F),
        ("Gold",   0xB9802B, 0xD8A24A),
        ("Plum",   0x6E4A78, 0xA77EB0),
        ("Slate",  0x4A6072, 0x7E97AA)
    ]

    static func tagColor(_ index: Int) -> Color {
        let c = tagColors[max(0, min(index, tagColors.count - 1))]
        return .dyn(c.light, c.dark)
    }

    // Typography
    static func serifTitle(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .serif) }
    static func serif(_ size: CGFloat) -> Font { .system(size: size, design: .serif) }
}
