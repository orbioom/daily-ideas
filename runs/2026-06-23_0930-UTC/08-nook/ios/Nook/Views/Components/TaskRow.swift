import SwiftUI

/// A compact row summarising a task with its due status, recurrence and
/// location. Used in Due, Tasks, Room detail and Equipment detail lists.
struct TaskRow: View {
    let task: MaintenanceTask
    let dueSoonWindow: Int
    var showStatus: Bool = true

    private var status: DueStatus {
        ScheduleEngine.status(for: task, dueSoonWindow: dueSoonWindow)
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(status.color.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: task.appliance?.kind.systemImage ?? task.room?.kind.systemImage ?? "wrench.adjustable")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(status.color)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                HStack(spacing: Theme.Spacing.sm) {
                    Text(ScheduleEngine.relativeLabel(for: task.nextDue))
                        .font(.caption)
                        .foregroundStyle(status == .overdue ? Theme.overdue : Theme.textSecondary)
                    if let room = task.room {
                        Label(room.name, systemImage: room.kind.systemImage)
                            .font(.caption2)
                            .foregroundStyle(Theme.textSecondary)
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
            Spacer(minLength: 0)
            if showStatus {
                StatusBadge(status: status, compact: true)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(task.title)
        .accessibilityValue("\(status.label). \(ScheduleEngine.relativeLabel(for: task.nextDue)).\(task.room.map { " In \($0.name)." } ?? "")")
        .accessibilityHint("Opens task details")
    }
}
