import SwiftUI

/// A compact row showing a task, its system, and its due status, with a Done action.
struct TaskRow: View {
    let task: MaintenanceTask
    let hemisphere: Hemisphere
    let dueSoonDays: Int
    var onDone: (() -> Void)? = nil

    private var bucket: DueBucket {
        ScheduleEngine.bucket(for: task,
                              hemisphere: hemisphere,
                              dueSoonDays: dueSoonDays)
    }

    private var dueColor: Color {
        switch bucket {
        case .overdue: return Theme.bad
        case .dueToday: return Theme.warn
        case .dueSoon: return Theme.warn
        case .later: return Theme.good
        }
    }

    private var dueText: String {
        guard let days = ScheduleEngine.daysUntilDue(for: task, hemisphere: hemisphere) else {
            return "Not scheduled"
        }
        if days < 0 {
            let n = -days
            return n == 1 ? "Overdue by 1 day" : "Overdue by \(n) days"
        } else if days == 0 {
            return "Due today"
        } else if days == 1 {
            return "Due tomorrow"
        } else {
            return "Due in \(days) days"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: SystemCatalog.symbol(for: task.systemName))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Theme.accentSoft))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(task.systemName)
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                    Text("•")
                        .foregroundStyle(Theme.inkFaint)
                    Text(dueText)
                        .font(Theme.rounded(12, .medium))
                        .foregroundStyle(dueColor)
                }
            }

            Spacer(minLength: 4)

            if let onDone {
                Button(action: onDone) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mark \(task.title) done")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.title), \(task.systemName), \(dueText)")
    }
}
