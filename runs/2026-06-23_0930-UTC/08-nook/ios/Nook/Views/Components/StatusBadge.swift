import SwiftUI

struct StatusBadge: View {
    let status: DueStatus
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.systemImage)
                .font(.caption2.weight(.semibold))
            Text(status.label)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, compact ? 3 : 4)
        .foregroundStyle(status.color)
        .background(status.color.opacity(0.14))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(status.label)
    }
}

struct RecurrenceBadge: View {
    let recurrence: Recurrence
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: recurrence.systemImage)
                .font(.caption2)
            Text(recurrence.shortLabel)
                .font(.caption2.weight(.medium))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .foregroundStyle(Theme.textSecondary)
        .background(Theme.bgSecondary)
        .clipShape(Capsule())
        .accessibilityLabel("Repeats \(recurrence.label)")
    }
}
