import SwiftUI

/// A small pill showing a game's status with its color and icon.
struct StatusChip: View {
    let status: GameStatus
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.symbol)
                .font(.system(size: compact ? 9 : 11, weight: .bold))
            if !compact {
                Text(status.label)
                    .font(Theme.rounded(12, .semibold))
            }
        }
        .foregroundStyle(status.color)
        .padding(.horizontal, compact ? 6 : 9)
        .padding(.vertical, compact ? 4 : 5)
        .background(status.color.opacity(0.15), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Status: \(status.label)")
    }
}
