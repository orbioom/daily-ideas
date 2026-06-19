import SwiftUI

enum TrekTheme {
    static let forestGreen = Color(red: 0.22, green: 0.60, blue: 0.22)
    static let trailBrown = Color(red: 0.55, green: 0.40, blue: 0.22)
    static let sunGold = Color(red: 0.95, green: 0.78, blue: 0.22)
    static let skyBlue = Color(red: 0.40, green: 0.72, blue: 0.88)
    static let stoneGray = Color(red: 0.52, green: 0.52, blue: 0.52)

    static func difficultyColor(_ diff: TrailDifficulty) -> Color {
        switch diff {
        case .easy: return .green
        case .moderate: return .blue
        case .hard: return .orange
        case .expert: return .red
        }
    }
}

struct TrekCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

extension View {
    func trekCard() -> some View { modifier(TrekCard()) }
}
