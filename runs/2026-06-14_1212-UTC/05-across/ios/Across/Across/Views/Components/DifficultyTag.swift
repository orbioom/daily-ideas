import SwiftUI

/// Small pill showing a puzzle's difficulty.
struct DifficultyTag: View {
    let difficulty: Difficulty

    private var color: Color {
        switch difficulty {
        case .easy: return Theme.good
        case .medium: return Theme.accent
        case .hard: return Color.dyn(0x7A4FB0, 0xB58CE6)
        }
    }

    var body: some View {
        Text(difficulty.title.uppercased())
            .font(Theme.mono(10, .bold))
            .tracking(0.5)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().stroke(color.opacity(0.6), lineWidth: 1)
            )
            .accessibilityLabel("Difficulty: \(difficulty.title)")
    }
}
