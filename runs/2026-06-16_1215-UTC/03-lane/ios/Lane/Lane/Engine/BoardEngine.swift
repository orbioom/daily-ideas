import Foundation

/// Pure, side-effect-free analytics over boards/columns/cards. Every computation
/// is guarded: no force-unwrap, no unchecked index, no unguarded division.
enum BoardEngine {

    // MARK: - Counts

    /// Card count per column for a board, in column order.
    static func cardCounts(for board: Board) -> [(column: BoardColumn, count: Int)] {
        board.orderedColumns.map { ($0, $0.cards.count) }
    }

    /// Columns that have exceeded their WIP limit.
    static func columnsOverWipLimit(for board: Board) -> [BoardColumn] {
        board.orderedColumns.filter { $0.isOverWipLimit }
    }

    static func isOverWipLimit(_ column: BoardColumn) -> Bool {
        column.isOverWipLimit
    }

    // MARK: - Progress

    /// Board progress in 0...1. Defined as the share of cards sitting in the last
    /// ("done") column. Guarded against empty boards.
    static func progress(for board: Board) -> Double {
        let all = board.allCards
        guard !all.isEmpty, let done = board.doneColumn else { return 0 }
        return Double(done.cards.count) / Double(all.count)
    }

    /// Aggregate checklist completion rollup across every card on a board, 0...1.
    static func checklistRollup(for board: Board) -> Double {
        let items = board.allCards.flatMap { $0.checklist }
        guard !items.isEmpty else { return 0 }
        let done = items.filter { $0.isDone }.count
        return Double(done) / Double(items.count)
    }

    static func completedCount(for board: Board) -> Int {
        board.doneColumn?.cards.count ?? 0
    }

    static func totalCards(for board: Board) -> Int {
        board.allCards.count
    }

    // MARK: - Due dates

    static func overdueCount(in boards: [Board], reference: Date = Date()) -> Int {
        allActiveCards(in: boards).filter {
            guard let due = $0.dueDate, !$0.isCompleted else { return false }
            return DateUtils.isOverdue(due, reference: reference)
        }.count
    }

    static func dueSoonCount(in boards: [Board], within days: Int = 3, reference: Date = Date()) -> Int {
        allActiveCards(in: boards).filter {
            guard let due = $0.dueDate, !$0.isCompleted else { return false }
            return DateUtils.isDueSoon(due, within: days, reference: reference)
        }.count
    }

    static func allActiveCards(in boards: [Board]) -> [Card] {
        boards.filter { !$0.isArchived }.flatMap { $0.allCards }
    }

    // MARK: - Throughput

    /// Cards completed per day over the trailing `days` window, oldest → newest.
    /// "Completed" = `completedDate` set (assigned when a card enters the done column).
    static func completedPerDay(in boards: [Board], days: Int = 7, reference: Date = Date()) -> [(date: Date, count: Int)] {
        let span = max(1, days)
        let startDay = DateUtils.startOfDay(DateUtils.addDays(-(span - 1), to: reference))
        var buckets: [Date: Int] = [:]
        for i in 0..<span {
            buckets[DateUtils.startOfDay(DateUtils.addDays(i, to: startDay))] = 0
        }
        for card in allActiveCards(in: boards) {
            guard let completed = card.completedDate else { continue }
            let day = DateUtils.startOfDay(completed)
            if buckets[day] != nil {
                buckets[day, default: 0] += 1
            }
        }
        return buckets.keys.sorted().map { ($0, buckets[$0] ?? 0) }
    }

    /// Cards completed per ISO week over the trailing `weeks` window, oldest → newest.
    static func completedPerWeek(in boards: [Board], weeks: Int = 6, reference: Date = Date()) -> [(weekStart: Date, count: Int)] {
        let span = max(1, weeks)
        let thisWeekStart = DateUtils.startOfWeek(reference)
        var weekStarts: [Date] = []
        for i in stride(from: span - 1, through: 0, by: -1) {
            weekStarts.append(DateUtils.startOfWeek(DateUtils.addDays(-7 * i, to: thisWeekStart)))
        }
        var buckets: [Date: Int] = [:]
        for w in weekStarts { buckets[w] = 0 }
        for card in allActiveCards(in: boards) {
            guard let completed = card.completedDate else { continue }
            let w = DateUtils.startOfWeek(completed)
            if buckets[w] != nil {
                buckets[w, default: 0] += 1
            }
        }
        return weekStarts.map { ($0, buckets[$0] ?? 0) }
    }

    /// The non-archived board with the most active (incomplete) cards.
    static func busiestBoard(in boards: [Board]) -> Board? {
        boards
            .filter { !$0.isArchived }
            .max { lhs, rhs in activeCardCount(lhs) < activeCardCount(rhs) }
    }

    static func activeCardCount(_ board: Board) -> Int {
        board.allCards.filter { !$0.isCompleted }.count
    }
}
