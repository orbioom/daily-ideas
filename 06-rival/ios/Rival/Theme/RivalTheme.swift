import SwiftUI

enum RivalTheme {
    static let accent = Color("AccentColor")
    static let red = Color("RivalRed")
    static let gold = Color("RivalGold")
    static let dark = Color("RivalDark")
    static let background = Color(uiColor: .systemBackground)
    static let secondary = Color(uiColor: .secondarySystemBackground)
    static let label = Color(uiColor: .label)
    static let secondaryLabel = Color(uiColor: .secondaryLabel)

    static func resultColor(_ result: PickResult) -> Color {
        switch result {
        case .pending: return .orange
        case .correct: return .green
        case .incorrect: return .red
        case .push: return .gray
        }
    }

    static func confidenceColor(_ level: ConfidenceLevel) -> Color {
        switch level {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .lock: return .red
        }
    }
}
