import SwiftUI

struct AgendaRowView: View {
    let card: Card
    let onComplete: () -> Void

    private var board: Board? { card.column?.board }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onComplete) {
                Image(systemName: card.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(card.isCompleted ? Theme.good : Theme.inkSoft)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(card.isCompleted ? "Completed" : "Mark complete")

            VStack(alignment: .leading, spacing: 4) {
                Text(card.title)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(card.isCompleted ? Theme.inkSoft : Theme.ink)
                    .strikethrough(card.isCompleted)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let board {
                        HStack(spacing: 3) {
                            Image(systemName: board.symbolName)
                                .font(.system(size: 9))
                            Text(board.name)
                                .font(.caption)
                        }
                        .foregroundStyle(Color(hex: UInt(max(0, board.colorHex))))
                    }
                    if card.priority != .none {
                        Image(systemName: card.priority.symbol)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(card.priority.color)
                    }
                }
            }

            Spacer()

            if let due = card.dueDate {
                DueDatePill(date: due, isCompleted: card.isCompleted)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
