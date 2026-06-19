import SwiftUI

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = TrekTheme.forestGreen

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct DifficultyBadge: View {
    let difficulty: TrailDifficulty

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: difficulty.icon)
                .font(.caption2)
                .accessibilityHidden(true)
            Text(difficulty.rawValue)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(TrekTheme.difficultyColor(difficulty))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(TrekTheme.difficultyColor(difficulty).opacity(0.15), in: Capsule())
        .accessibilityLabel("Difficulty: \(difficulty.rawValue)")
    }
}

struct StarRatingView: View {
    let rating: Int
    var maxRating: Int = 5

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .font(.caption)
                    .foregroundStyle(i <= rating ? TrekTheme.sunGold : Color.secondary)
            }
        }
        .accessibilityLabel("\(rating) out of \(maxRating) stars")
    }
}
