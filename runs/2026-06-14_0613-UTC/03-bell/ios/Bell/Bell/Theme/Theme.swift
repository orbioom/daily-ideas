import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    static func dyn(_ l: UInt, _ d: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? d : l
            return UIColor(red: CGFloat((h >> 16) & 0xFF) / 255,
                           green: CGFloat((h >> 8) & 0xFF) / 255,
                           blue: CGFloat(h & 0xFF) / 255,
                           alpha: 1)
        })
    }
}

enum Theme {
    // MARK: - Brand
    /// Jade / teal accent — serene, dark-first.
    static let accent = Color(hex: 0x2FA08C)
    static let accentSoft = Color.dyn(0x4FB8A4, 0x2FA08C)
    static let accentDeep = Color.dyn(0x1F7A6A, 0x3FB39C)

    // MARK: - Surfaces (light, dark)
    static let background = Color.dyn(0xF4F7F6, 0x0E1413)
    static let surface = Color.dyn(0xFFFFFF, 0x161E1C)
    static let surfaceRaised = Color.dyn(0xFAFCFB, 0x1E2826)
    static let separator = Color.dyn(0xE2E8E6, 0x2A3432)

    // MARK: - Text
    static let textPrimary = Color.dyn(0x141A19, 0xF1F5F4)
    static let textSecondary = Color.dyn(0x55615E, 0x9AA8A4)
    static let textTertiary = Color.dyn(0x8A9591, 0x66726F)

    // MARK: - Semantic
    static let success = Color.dyn(0x2E8B6F, 0x4FC3A1)
    static let warning = Color.dyn(0xC08A3E, 0xE0B36A)
    static let danger = Color.dyn(0xC0503E, 0xE08070)

    // MARK: - Fonts
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    // MARK: - Metrics
    static let corner: CGFloat = 18
    static let cornerSmall: CGFloat = 12
    static let spacing: CGFloat = 16
}
