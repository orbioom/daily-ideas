import SwiftUI
import SwiftData

/// The tappable completion circle. Tapping it completes (or advances) the task
/// with a haptic and a calm animation. Fully accessible.
struct CheckCircle: View {
    let isDone: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .strokeBorder(isDone ? tint : Brand.text3.opacity(0.5), lineWidth: 2)
                    .frame(width: 24, height: 24)
                if isDone {
                    Circle()
                        .fill(tint)
                        .frame(width: 24, height: 24)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Completion")
        .accessibilityValue(isDone ? "Completed" : "Not completed")
        .accessibilityAddTraits(.isButton)
    }
}

/// A single task row used across Today, Upcoming, project detail, and filtered
/// lists. Tapping the circle toggles done; tapping the body opens the editor.
struct TaskRow: View {
    @Bindable var task: TaskItem
    var showProject: Bool = true
    var showDate: Bool = false
    var onToggle: () -> Void
    var onOpen: () -> Void

    private var tint: Color {
        if let project = task.project { return Color(brandHex: project.colorHex) }
        return Brand.magic
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CheckCircle(isDone: task.isDone, tint: tint, action: onToggle)
                .padding(.top, 1)

            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        if task.priority != .none {
                            Image(systemName: task.priority.symbol)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(task.priority.tint)
                                .accessibilityHidden(true)
                        }
                        Text(task.title)
                            .font(.body)
                            .foregroundStyle(task.isDone ? Brand.text3 : Brand.text)
                            .strikethrough(task.isDone, color: Brand.text3)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }

                    metadata
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 7)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var metadata: some View {
        let chips = metaChips
        if !chips.isEmpty {
            HStack(spacing: 8) {
                ForEach(chips, id: \.text) { chip in
                    Label {
                        Text(chip.text)
                    } icon: {
                        if let symbol = chip.symbol {
                            Image(systemName: symbol).accessibilityHidden(true)
                        }
                    }
                    .font(Brand.mono(11, weight: .medium))
                    .foregroundStyle(chip.tint)
                    .labelStyle(.titleAndIcon)
                }
            }
        }
    }

    private struct Meta { let text: String; let symbol: String?; let tint: Color }

    private var metaChips: [Meta] {
        var chips: [Meta] = []
        if task.recurrence.isRepeating {
            chips.append(Meta(text: shortRecurrence, symbol: "repeat", tint: Brand.info))
        }
        if showDate, let anchor = task.anchorDate {
            chips.append(Meta(text: dateLabel(anchor), symbol: "calendar", tint: dateTint(anchor)))
        } else if let due = task.dueDate, !showDate {
            // On Today, show due-time only.
            if CruxDate.hasMeaningfulTime(due) {
                chips.append(Meta(text: CruxDate.time(due), symbol: "clock", tint: dateTint(due)))
            }
        }
        if showProject, let project = task.project {
            chips.append(Meta(text: project.name, symbol: "circle.fill", tint: Color(brandHex: project.colorHex)))
        }
        let sub = task.subtaskProgress
        if sub.total > 0 {
            chips.append(Meta(text: "\(sub.done)/\(sub.total)", symbol: "checklist", tint: Brand.text2))
        }
        if let first = task.tags.first {
            let extra = task.tags.count > 1 ? " +\(task.tags.count - 1)" : ""
            chips.append(Meta(text: "#\(first.name)\(extra)", symbol: nil, tint: Brand.text3))
        }
        return chips
    }

    private var shortRecurrence: String {
        switch task.recurrence {
        case .everyN: return "Every \(max(1, task.recurrenceInterval))d"
        case .daily: return "Daily"
        case .weekdays: return "Weekdays"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .none: return ""
        }
    }

    private func dateLabel(_ date: Date) -> String {
        if CruxDate.hasMeaningfulTime(date) {
            return "\(CruxDate.relativeDay(date)) \(CruxDate.time(date))"
        }
        return CruxDate.relativeDay(date)
    }

    private func dateTint(_ date: Date) -> Color {
        date < Calendar.current.startOfDay(for: .now) ? Brand.danger : Brand.text2
    }
}
