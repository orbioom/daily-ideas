import SwiftUI

/// Compact status pill (Optimal / In Range / High / Low …).
struct StatusChip: View {
    let status: MarkerStatus
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.symbol)
                .font(.system(size: compact ? 10 : 12, weight: .semibold))
            Text(status.rawValue)
                .font(Theme.rounded(compact ? 11 : 12, .semibold))
        }
        .foregroundStyle(status.color)
        .padding(.horizontal, compact ? 7 : 9)
        .padding(.vertical, compact ? 3 : 5)
        .background(status.color.opacity(0.14))
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Status")
        .accessibilityValue(status.rawValue)
    }
}
