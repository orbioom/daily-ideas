import SwiftUI

struct BingoTheme {
    static let navy = Color(hex: "#1A1B3A")
    static let gold = Color(hex: "#FFD700")
    static let red = Color(hex: "#E63946")
    static let white = Color.white
    static let lightNavy = Color(hex: "#2D2E5F")
    static let darkGold = Color(hex: "#B8960C")

    static let cardBackground = Color(hex: "#242550")
    static let markedCell = Color(hex: "#E63946")
    static let freeCell = Color(hex: "#FFD700")
    static let unmarkedCell = Color(hex: "#2D2E5F")
    static let headerCell = Color(hex: "#1A1B3A")
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

struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.bold())
            .foregroundColor(BingoTheme.navy)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(BingoTheme.gold)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

struct NavyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.bold())
            .foregroundColor(BingoTheme.gold)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(BingoTheme.navy)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(BingoTheme.gold, lineWidth: 2))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}
