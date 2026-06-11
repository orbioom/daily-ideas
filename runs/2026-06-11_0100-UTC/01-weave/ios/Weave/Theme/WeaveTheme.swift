import SwiftUI

enum WeaveTheme {
    // Difficulty colors
    static let yellow = Color(red: 0.97, green: 0.83, blue: 0.20)
    static let green  = Color(red: 0.37, green: 0.74, blue: 0.46)
    static let blue   = Color(red: 0.34, green: 0.62, blue: 0.88)
    static let purple = Color(red: 0.68, green: 0.40, blue: 0.82)

    static func difficultyColor(_ d: Int) -> Color {
        switch d {
        case 1: return yellow
        case 2: return green
        case 3: return blue
        default: return purple
        }
    }

    static let cardBackground = Color("CardBackground")
    static let selectedTint   = Color("SelectedTint")
    static let surface        = Color("Surface")

    static let tileCorner: CGFloat = 10
    static let tileFont = Font.system(size: 14, weight: .semibold, design: .rounded)
    static let categoryFont = Font.system(size: 15, weight: .bold, design: .rounded)
}
