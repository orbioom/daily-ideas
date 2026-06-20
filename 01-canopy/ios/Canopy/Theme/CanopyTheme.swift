import SwiftUI

// MARK: - Hex color initializer
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

// MARK: - Canopy Brand Colors
extension Color {
    static let canopyGreen = Color(hex: "2D6A4F")
    static let canopyLight = Color(hex: "52B788")
    static let canopyBark  = Color(hex: "8B5E3C")
    static let canopySky   = Color(hex: "B7E4C7")

    // Adaptive background
    static let canopyBackground = Color("CanopyBackground")
    static let canopySurface    = Color("CanopySurface")
}

// MARK: - Theme constants
enum CanopyTheme {
    static let cornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 10
    static let ringLineWidth: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24

    static func ringColor(progress: Double) -> Color {
        switch progress {
        case ..<0.6:
            return .canopyLight
        case 0.6..<0.85:
            return Color(hex: "F4A261")  // orange
        default:
            return Color(hex: "E63946")  // red
        }
    }
}
