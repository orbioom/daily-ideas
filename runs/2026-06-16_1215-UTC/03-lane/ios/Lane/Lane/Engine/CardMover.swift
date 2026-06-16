import Foundation
import SwiftData

/// Mutating operations on the board graph. Kept separate from the pure
/// `BoardEngine`. All index math is guarded — these never crash on bad input.
enum CardMover {

    // MARK: - sortIndex compaction

    /// Rewrites sortIndex to 0,1,2,… preserving current order. Idempotent.
    static func compact(_ cards: [Card]) {
        let ordered = cards.sorted { $0.sortIndex < $1.sortIndex }
        for (i, card) in ordered.enumerated() {
            card.sortIndex = i
        }
    }

    static func compactColumns(_ columns: [BoardColumn]) {
        let ordered = columns.sorted { $0.sortIndex < $1.sortIndex }
        for (i, col) in ordered.enumerated() {
            col.sortIndex = i
        }
    }

    static func compactChecklist(_ items: [ChecklistItem]) {
        let ordered = items.sorted { $0.sortIndex < $1.sortIndex }
        for (i, item) in ordered.enumerated() {
            item.sortIndex = i
        }
    }

    // MARK: - Moving cards between columns

    /// Move a card to the end of `target` column, updating relationships, sort
    /// order, and completed state. Safe to call when already in `target`.
    static func move(_ card: Card, to target: BoardColumn, context: ModelContext) {
        let source = card.column

        if let source, source.id == target.id {
            // Same column — nothing to move, but keep ordering tidy.
            compact(source.cards)
            return
        }

        // Detach from source.
        if let source {
            source.cards.removeAll { $0.id == card.id }
            compact(source.cards)
        }

        // Attach to target at the end.
        let maxIndex = target.cards.map(\.sortIndex).max() ?? -1
        card.sortIndex = maxIndex + 1
        card.column = target
        target.cards.append(card)
        compact(target.cards)

        updateCompletion(for: card, in: target)
    }

    /// Set or clear `completedDate` based on whether `column` is its board's last column.
    static func updateCompletion(for card: Card, in column: BoardColumn) {
        let isDoneColumn = column.board?.doneColumn?.id == column.id
        if isDoneColumn {
            if card.completedDate == nil {
                card.completedDate = Date()
            }
        } else {
            card.completedDate = nil
        }
    }

    /// Mark a card complete by moving it to the board's done column (if any).
    static func complete(_ card: Card, context: ModelContext) {
        guard let done = card.column?.board?.doneColumn else {
            card.completedDate = Date()
            return
        }
        move(card, to: done, context: context)
    }

    // MARK: - Reordering within a column

    /// Apply an IndexSet move (from `.onMove`) to a column's ordered cards.
    static func reorder(in column: BoardColumn, from offsets: IndexSet, to destination: Int) {
        var ordered = column.orderedCards
        guard !ordered.isEmpty else { return }
        let safeDestination = min(max(0, destination), ordered.count)
        ordered.move(fromOffsets: offsets, toOffset: safeDestination)
        for (i, card) in ordered.enumerated() {
            card.sortIndex = i
        }
    }

    static func reorderChecklist(in card: Card, from offsets: IndexSet, to destination: Int) {
        var ordered = card.orderedChecklist
        guard !ordered.isEmpty else { return }
        let safeDestination = min(max(0, destination), ordered.count)
        ordered.move(fromOffsets: offsets, toOffset: safeDestination)
        for (i, item) in ordered.enumerated() {
            item.sortIndex = i
        }
    }

    static func reorderColumns(in board: Board, from offsets: IndexSet, to destination: Int) {
        var ordered = board.orderedColumns
        guard !ordered.isEmpty else { return }
        let safeDestination = min(max(0, destination), ordered.count)
        ordered.move(fromOffsets: offsets, toOffset: safeDestination)
        for (i, col) in ordered.enumerated() {
            col.sortIndex = i
        }
        // Done-column membership may have changed; re-evaluate completion.
        for col in board.orderedColumns {
            for card in col.cards {
                updateCompletion(for: card, in: col)
            }
        }
    }

    static func reorderBoards(_ boards: [Board], from offsets: IndexSet, to destination: Int) {
        var ordered = boards.sorted { $0.sortIndex < $1.sortIndex }
        guard !ordered.isEmpty else { return }
        let safeDestination = min(max(0, destination), ordered.count)
        ordered.move(fromOffsets: offsets, toOffset: safeDestination)
        for (i, board) in ordered.enumerated() {
            board.sortIndex = i
        }
    }
}
