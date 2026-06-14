import SwiftUI

/// A small star-prefixed score chip. Shows "—" when unrated, "•" when hidden.
struct ScoreChip: View {
    let score: Int
    var hidden: Bool = false

    private var label: String {
        if hidden { return "•" }
        return score <= 0 ? "—" : "\(min(score, 10))"
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: 10, weight: .bold))
                .accessibilityHidden(true)
            Text(label)
                .font(Theme.rounded(13, .bold))
                .monospacedDigit()
        }
        .foregroundStyle(Theme.gold)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Theme.gold.opacity(0.16)))
        .accessibilityLabel(score <= 0 ? "Unrated" : "Score \(min(score, 10)) of 10")
    }
}
