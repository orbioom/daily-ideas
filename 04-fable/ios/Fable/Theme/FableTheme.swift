import SwiftUI

enum FableTheme {
    static let accent = Color("AccentColor")
    static let gold = Color("FableGold")
    static let purple = Color("FablePurple")
    static let night = Color("FableNight")
    static let background = Color(uiColor: .systemBackground)
    static let secondary = Color(uiColor: .secondarySystemBackground)
    static let label = Color(uiColor: .label)
    static let secondaryLabel = Color(uiColor: .secondaryLabel)

    static func genreColor(_ genre: StoryGenre) -> Color {
        switch genre {
        case .adventure: return .orange
        case .fantasy: return .purple
        case .animals: return .green
        case .friendship: return .pink
        case .mystery: return .indigo
        case .bedtime: return .blue
        case .silly: return .yellow
        case .space: return .cyan
        }
    }
}
