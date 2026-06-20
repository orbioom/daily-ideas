import SwiftUI

extension Color {
    static let scriptAmber = Color(red: 0.957, green: 0.635, blue: 0.380)
    static let scriptPaper = Color(red: 0.980, green: 0.976, blue: 0.969)
    static let scriptInk = Color(red: 0.110, green: 0.110, blue: 0.118)
    static let scriptDark = Color(red: 0.110, green: 0.110, blue: 0.118)
    static let scriptSurface = Color(.systemBackground)
    static let scriptSecondary = Color(.secondarySystemBackground)

    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
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

struct ScriptTheme {
    // Semantic color aliases
    static let accent = Color.scriptAmber
    static let backgroundDark = Color.scriptDark
    static let backgroundLight = Color.scriptPaper

    static let genres = [
        "Action", "Adventure", "Animation", "Biography", "Comedy",
        "Crime", "Documentary", "Drama", "Fantasy", "Horror",
        "Musical", "Mystery", "Romance", "Sci-Fi", "Short Film",
        "Thriller", "Western", "War", "Family", "Other"
    ]

    static let draftNumbers = [
        "First Draft", "Second Draft", "Third Draft",
        "Revised Draft", "Production Draft", "Shooting Script"
    ]

    static let colorTags = [
        "#F4A261", "#E76F51", "#2A9D8F", "#264653",
        "#457B9D", "#1D3557", "#6D6875", "#B5838D"
    ]

    static func colorTag(_ hex: String) -> Color {
        guard hex.count >= 7 else { return .scriptAmber }
        let r = Double(Int(hex.dropFirst(1).prefix(2), radix: 16) ?? 200) / 255
        let g = Double(Int(hex.dropFirst(3).prefix(2), radix: 16) ?? 200) / 255
        let b = Double(Int(hex.dropFirst(5).prefix(2), radix: 16) ?? 200) / 255
        return Color(red: r, green: g, blue: b)
    }

    static func courierFont(size: Double = 12) -> Font {
        Font.custom("Courier", size: size)
    }

    static func courierUIFont(size: CGFloat = 12) -> UIFont {
        UIFont(name: "Courier", size: size) ?? UIFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }
}
