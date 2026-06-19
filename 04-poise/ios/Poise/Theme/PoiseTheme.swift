import SwiftUI

enum PoiseTheme {
    // Primary sky blue
    static let sky = Color(red: 0.055, green: 0.647, blue: 0.914)
    static let skyLight = Color(red: 0.40, green: 0.80, blue: 0.97)
    static let skyDark = Color(red: 0.04, green: 0.47, blue: 0.70)

    // Backgrounds
    static let backgroundPrimary = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)

    // Surface cards
    static let cardBackground = Color(.secondarySystemBackground)

    // Text
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textMuted = Color(.tertiaryLabel)

    // Category colors
    static func categoryColor(for category: ExerciseCategory) -> Color {
        switch category {
        case .neck: return sky
        case .shoulders: return Color.teal
        case .eyes: return Color.purple
        case .wrists: return Color.orange
        case .back: return Color.green
        }
    }

    // Gradient
    static let skyGradient = LinearGradient(
        colors: [skyDark, sky],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let breakGradient = LinearGradient(
        colors: [sky, skyLight],
        startPoint: .top,
        endPoint: .bottom
    )
}
