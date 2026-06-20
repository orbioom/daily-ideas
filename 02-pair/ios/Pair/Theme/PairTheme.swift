import SwiftUI

enum PairTheme {
    static let background = Color(red: 0.102, green: 0.106, blue: 0.227)       // #1A1B3A
    static let accent = Color(red: 1.0, green: 0.42, blue: 0.42)               // #FF6B6B
    static let cardBack = Color(red: 0.176, green: 0.169, blue: 0.412)         // #2D2B69
    static let surface = Color(red: 0.15, green: 0.16, blue: 0.32)
    static let surfaceSecondary = Color(red: 0.20, green: 0.21, blue: 0.38)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.7)

    static func cardSize(for gridSize: GridSize) -> CGFloat {
        switch gridSize {
        case .easy: return 80
        case .medium: return 72
        case .hard: return 60
        }
    }

    static func fontSize(for gridSize: GridSize) -> CGFloat {
        switch gridSize {
        case .easy: return 34
        case .medium: return 30
        case .hard: return 24
        }
    }
}
