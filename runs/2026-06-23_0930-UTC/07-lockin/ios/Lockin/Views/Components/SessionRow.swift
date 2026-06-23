import SwiftUI

/// Compact row describing one focus session.
struct SessionRow: View {
    let session: FocusSession

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d · h:mm a"
        return f
    }()

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill((session.project?.color ?? Theme.Palette.textSecondary).opacity(0.16))
                    .frame(width: 40, height: 40)
                Image(systemName: session.mode.symbol)
                    .font(.subheadline)
                    .foregroundStyle(session.project?.color ?? Theme.Palette.textSecondary)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(TimeFormat.durationSeconds(session.focusedSeconds))
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.Palette.textPrimary)
                    if !session.wasCompleted {
                        Text("ended early")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Theme.Palette.danger)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.Palette.danger.opacity(0.14))
                            .clipShape(Capsule())
                    }
                }
                Text(Self.timeFormatter.string(from: session.startedAt))
                    .font(.caption)
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(session.project?.name ?? "Unassigned")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(session.project?.color ?? Theme.Palette.textSecondary)
                if session.distractionCount > 0 {
                    Label("\(session.distractionCount)", systemImage: "exclamationmark.bubble")
                        .font(.caption2)
                        .foregroundStyle(Theme.Palette.warm)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = [
            "\(session.mode.label) session",
            TimeFormat.durationSeconds(session.focusedSeconds),
            session.project?.name ?? "Unassigned",
            session.wasCompleted ? "completed" : "ended early"
        ]
        if session.distractionCount > 0 {
            parts.append("\(session.distractionCount) distractions")
        }
        return parts.joined(separator: ", ")
    }
}
