import SwiftUI

enum HaloTheme {
    // MARK: - Colors
    static let background = Color(hex: "#0D0D1A")
    static let surface = Color(hex: "#16162A")
    static let surfaceElevated = Color(hex: "#1E1E35")
    static let primary = Color(hex: "#7B5EA7")
    static let accent = Color(hex: "#C084FC")
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.7)
    static let textTertiary = Color(white: 0.45)

    // MARK: - Typography
    static let displayFont = Font.system(size: 34, weight: .bold, design: .rounded)
    static let titleFont = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let headlineFont = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let bodyFont = Font.system(size: 15, weight: .regular, design: .rounded)
    static let captionFont = Font.system(size: 12, weight: .regular, design: .rounded)
    static let labelFont = Font.system(size: 13, weight: .medium, design: .rounded)

    // MARK: - Spacing
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacingXXL: CGFloat = 48

    // MARK: - Corner Radii
    static let radiusS: CGFloat = 8
    static let radiusM: CGFloat = 12
    static let radiusL: CGFloat = 20
    static let radiusXL: CGFloat = 28

    // MARK: - Glow
    static func glowShadow(color: Color, radius: CGFloat = 20) -> some View {
        Rectangle()
            .fill(Color.clear)
            .shadow(color: color.opacity(0.6), radius: radius)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
