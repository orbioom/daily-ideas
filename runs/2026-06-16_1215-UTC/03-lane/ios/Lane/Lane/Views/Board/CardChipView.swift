import SwiftUI

/// Compact card representation shown inside a column.
struct CardChipView: View {
    let card: Card
    let isDoneColumn: Bool

    private var labels: [Label] { card.labels }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            if !labels.isEmpty {
                HStack(spacing: 4) {
                    ForEach(labels.prefix(5)) { label in
                        LabelChip(name: label.name, colorHex: label.colorHex, compact: true)
                    }
                }
            }

            HStack(alignment: .top, spacing: 6) {
                if card.priority != .none {
                    Image(systemName: card.priority.symbol)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(card.priority.color)
                        .accessibilityHidden(true)
                }
                Text(card.title)
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(card.isCompleted ? Theme.inkSoft : Theme.ink)
                    .strikethrough(card.isCompleted, color: Theme.inkSoft)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }

            if hasMeta {
                HStack(spacing: 8) {
                    if let due = card.dueDate {
                        DueDatePill(date: due, isCompleted: card.isCompleted)
                    }
                    if !card.checklist.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "checklist")
                                .font(.system(size: 10, weight: .semibold))
                            Text("\(card.checklistDoneCount)/\(card.checklist.count)")
                                .font(Theme.rounded(11, .semibold))
                        }
                        .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer(minLength: 0)
                    if isDoneColumn && card.isCompleted {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.good)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Opens card details")
    }

    private var hasMeta: Bool {
        card.dueDate != nil || !card.checklist.isEmpty || (isDoneColumn && card.isCompleted)
    }

    private var accessibilityText: String {
        var parts: [String] = [card.title]
        if card.priority != .none { parts.append("\(card.priority.rawValue) priority") }
        if let due = card.dueDate { parts.append("due \(DateUtils.relativeLabel(for: due))") }
        if !card.checklist.isEmpty { parts.append("\(card.checklistDoneCount) of \(card.checklist.count) checked") }
        if card.isCompleted { parts.append("completed") }
        return parts.joined(separator: ", ")
    }
}
