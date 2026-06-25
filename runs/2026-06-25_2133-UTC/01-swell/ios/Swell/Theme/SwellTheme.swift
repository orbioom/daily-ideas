import SwiftUI

enum SwellTheme {
    static let navy = Color(red: 0.039, green: 0.086, blue: 0.157)
    static let teal = Color(red: 0.0, green: 0.761, blue: 0.796)
    static let coral = Color(red: 1.0, green: 0.420, blue: 0.420)
    static let sand = Color(red: 0.965, green: 0.937, blue: 0.871)
    static let deepBlue = Color(red: 0.059, green: 0.298, blue: 0.502)
    static let foam = Color(red: 0.937, green: 0.980, blue: 0.988)
}

extension SessionConditions {
    var color: Color {
        switch self {
        case .epic:   return Color(red: 1.0, green: 0.78, blue: 0.0)
        case .good:   return SwellTheme.teal
        case .fair:   return Color(red: 0.565, green: 0.792, blue: 0.976)
        case .poor:   return Color(red: 0.62, green: 0.72, blue: 0.77)
        }
    }
}

extension SpotDifficulty {
    var swiftUIColor: Color {
        switch self {
        case .beginner:     return .green
        case .intermediate: return .yellow
        case .advanced:     return .orange
        case .expert:       return .red
        }
    }
}

struct RatingView: View {
    let rating: Int
    let maxRating: Int
    let size: CGFloat

    init(rating: Int, maxRating: Int = 5, size: CGFloat = 14) {
        self.rating = rating
        self.maxRating = maxRating
        self.size = size
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(i <= rating ? SwellTheme.teal : Color.secondary)
            }
        }
    }
}

struct ConditionBadge: View {
    let conditions: SessionConditions

    var body: some View {
        Label(conditions.rawValue, systemImage: conditions.sfSymbol)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(conditions.color.opacity(0.18))
            .foregroundStyle(conditions.color)
            .clipShape(Capsule())
    }
}

struct WaveHeightView: View {
    let feet: Double

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "water.waves")
            Text(String(format: "%.1f ft", feet))
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(SwellTheme.teal)
    }
}

struct HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
