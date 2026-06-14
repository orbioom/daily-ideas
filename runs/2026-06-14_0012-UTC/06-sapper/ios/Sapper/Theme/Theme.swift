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

/// Central design tokens for Sapper. Every color/font referenced in views lives here.
enum Theme {
    // Surfaces
    static let bg = Color.dyn(0xF4F6FA, 0x12151C)
    static let surface = Color.dyn(0xFFFFFF, 0x1B1F29)
    static let surfaceAlt = Color.dyn(0xEAEEF5, 0x232835)

    // Ink
    static let ink = Color.dyn(0x14181F, 0xF2F4F8)
    static let inkSoft = Color.dyn(0x4C5563, 0xAEB6C4)
    static let inkFaint = Color.dyn(0x8A93A3, 0x6B7382)

    // Accent (confident blue)
    static let accent = Color.dyn(0x286ED2, 0x5C9BF5)
    static let accentSoft = Color.dyn(0xDCE8FB, 0x223047)

    static let hairline = Color.dyn(0xD9DFE9, 0x2D3340)
    static let good = Color.dyn(0x1E9E63, 0x4FD39A)
    static let bad = Color.dyn(0xD23B3B, 0xF06A6A)

    // Game-board specific tints
    static let cellHidden = Color.dyn(0xDDE4EE, 0x2A3140)
    static let cellHiddenTop = Color.dyn(0xF1F5FB, 0x353D4E)
    static let cellRevealed = Color.dyn(0xF7F9FC, 0x191D26)
    static let flag = Color.dyn(0xD23B3B, 0xF06A6A)

    /// Classic per-number colors, tuned for contrast in both modes.
    static func numberColor(_ n: Int) -> Color {
        switch n {
        case 1: return Color.dyn(0x1C5FD0, 0x6FA8FF) // blue
        case 2: return Color.dyn(0x1E8A4C, 0x57D08C) // green
        case 3: return Color.dyn(0xCB2E2E, 0xF1726F) // red
        case 4: return Color.dyn(0x1A2C7A, 0x8FA0E8) // navy
        case 5: return Color.dyn(0x8A2222, 0xD98A6A) // maroon
        case 6: return Color.dyn(0x117B86, 0x57C9D4) // teal
        case 7: return Color.dyn(0x161A22, 0xE6EAF0) // ink/black
        case 8: return Color.dyn(0x6B7382, 0x9AA3B2) // gray
        default: return inkSoft
        }
    }

    // Font helpers
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
