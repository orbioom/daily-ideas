import SwiftUI

/// Small "Pro" lock badge used to mark gated controls.
struct ProLockBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "lock.fill")
                .font(.system(size: 9, weight: .bold))
            Text("Pro")
                .font(Theme.rounded(11, .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Theme.heroGradient, in: Capsule())
        .accessibilityLabel("Pro feature")
    }
}

/// A due-date pill colored by overdue / due-soon / future.
struct DueDatePill: View {
    let date: Date
    let isCompleted: Bool

    var body: some View {
        let overdue = !isCompleted && DateUtils.isOverdue(date)
        let soon = !isCompleted && DateUtils.isDueSoon(date)
        let color: Color = overdue ? Theme.bad : (soon ? Theme.warn : Theme.inkSoft)
        HStack(spacing: 3) {
            Image(systemName: overdue ? "exclamationmark.circle.fill" : "calendar")
                .font(.system(size: 10, weight: .semibold))
            Text(DateUtils.relativeLabel(for: date))
                .font(Theme.rounded(11, .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(color.opacity(0.14), in: Capsule())
        .accessibilityLabel("Due \(DateUtils.relativeLabel(for: date))\(overdue ? ", overdue" : "")")
    }
}
