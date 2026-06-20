import SwiftUI

enum PieceTheme {
    static let amber = Color(hue: 0.09, saturation: 0.92, brightness: 0.97)
    static let warmBrown = Color(hue: 0.07, saturation: 0.7, brightness: 0.35)
    static let darkBg = Color(hue: 0.07, saturation: 0.6, brightness: 0.10)
    static let cardBg = Color(hue: 0.07, saturation: 0.4, brightness: 0.16)
    static let subtleText = Color.white.opacity(0.55)

    static let completionGreen = Color(hue: 0.35, saturation: 0.8, brightness: 0.75)

    static func difficultyColor(_ d: PuzzleDifficulty) -> Color {
        switch d {
        case .beginner:     return Color(hue:0.33, saturation:0.75, brightness:0.75)
        case .intermediate: return Color(hue:0.13, saturation:0.90, brightness:0.98)
        case .expert:       return Color(hue:0.0,  saturation:0.85, brightness:0.85)
        }
    }
}
