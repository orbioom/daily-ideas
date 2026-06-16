import Foundation

/// A labelled count used by charts (genres, histogram bins).
struct CountItem: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
}

/// A month bucket of pages read in the current year.
struct MonthPages: Identifiable {
    let id = UUID()
    let monthIndex: Int   // 1...12
    let label: String     // "Jan"…"Dec"
    let pages: Int
}

/// The fully-computed stats snapshot for the Stats screen.
struct ReadingStats {
    var booksFinishedThisYear: Int = 0
    var readingGoal: Int = 0
    var totalPagesRead: Int = 0
    var averageRating: Double = 0
    var ratedCount: Int = 0
    var longestStreak: Int = 0
    var currentlyReading: Int = 0
    var averageDaysToFinish: Double = 0
    var genreCounts: [CountItem] = []
    var ratingHistogram: [CountItem] = []
    var pagesPerMonth: [MonthPages] = []

    var goalProgress: Double {
        guard readingGoal > 0 else { return 0 }
        return min(1, Double(booksFinishedThisYear) / Double(readingGoal))
    }

    var isEmpty: Bool {
        totalPagesRead == 0 && booksFinishedThisYear == 0 && currentlyReading == 0
    }
}

/// Pure, guarded reading analytics. No SwiftData, no UI — fully testable.
enum ReadingEngine {

    private static let calendar = Calendar.current

    /// Abbreviated month names ("Jan"…"Dec"). `shortMonthSymbols` lives on DateFormatter.
    private static let monthSymbols: [String] = {
        let f = DateFormatter()
        return f.shortMonthSymbols ?? ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                       "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    }()

    // MARK: - Per-book

    /// Fractional progress 0...1 for a single book. Guards a zero page count.
    static func progress(currentPage: Int, pageCount: Int) -> Double {
        guard pageCount > 0 else { return 0 }
        return min(1, max(0, Double(currentPage) / Double(pageCount)))
    }

    /// Average pages/day from a book's sessions over the span of distinct reading days.
    /// Returns 0 when there isn't enough data.
    static func pace(for sessions: [ReadingSession]) -> Double {
        let valid = sessions.filter { $0.pagesRead > 0 }
        guard !valid.isEmpty else { return 0 }
        let totalPages = valid.reduce(0) { $0 + $1.pagesRead }
        let days = distinctDayCount(valid.map { $0.date })
        guard days > 0 else { return 0 }
        return Double(totalPages) / Double(days)
    }

    /// Projected finish date for a book, given its pace. Nil when pace is zero
    /// or the book is already done.
    static func projectedFinish(pagesRemaining: Int, pace: Double, from start: Date = .now) -> Date? {
        guard pagesRemaining > 0, pace > 0 else { return nil }
        let daysNeeded = Double(pagesRemaining) / pace
        let wholeDays = Int(daysNeeded.rounded(.up))
        return calendar.date(byAdding: .day, value: wholeDays, to: start)
    }

    // MARK: - Library-wide

    /// Builds the full stats snapshot from all books and the yearly goal.
    static func computeStats(books: [Book], goal: Int) -> ReadingStats {
        var stats = ReadingStats()
        stats.readingGoal = max(0, goal)

        let year = calendar.component(.year, from: .now)

        // Books finished this year.
        stats.booksFinishedThisYear = books.filter { book in
            guard book.shelf == .finished, let f = book.finishedDate else { return false }
            return calendar.component(.year, from: f) == year
        }.count

        stats.currentlyReading = books.filter { $0.shelf == .reading }.count

        // Total pages read across all sessions.
        let allSessions = books.flatMap { $0.sessions }
        stats.totalPagesRead = allSessions.reduce(0) { $0 + max(0, $1.pagesRead) }

        // Ratings.
        let ratings = books.compactMap { $0.rating }.filter { $0 > 0 }
        stats.ratedCount = ratings.count
        if !ratings.isEmpty {
            stats.averageRating = ratings.reduce(0, +) / Double(ratings.count)
        }

        // Average days-to-finish for finished books with both dates.
        let spans: [Int] = books.compactMap { book in
            guard book.shelf == .finished,
                  let s = book.startedDate, let f = book.finishedDate,
                  f >= s else { return nil }
            let days = calendar.dateComponents([.day], from: s, to: f).day ?? 0
            return max(1, days)
        }
        if !spans.isEmpty {
            stats.averageDaysToFinish = Double(spans.reduce(0, +)) / Double(spans.count)
        }

        // Longest reading streak — distinct days with any session.
        stats.longestStreak = longestStreak(in: allSessions.map { $0.date })

        // By-genre counts (primary genre / first tag).
        stats.genreCounts = genreCounts(books: books)

        // Ratings histogram (1...5 rounded).
        stats.ratingHistogram = ratingHistogram(ratings: ratings)

        // Pages per month for the current year.
        stats.pagesPerMonth = pagesPerMonth(sessions: allSessions, year: year)

        return stats
    }

    static func genreCounts(books: [Book]) -> [CountItem] {
        var dict: [String: Int] = [:]
        for book in books {
            // A book contributes to each of its tags; untagged books count once.
            if book.tags.isEmpty {
                dict["Untagged", default: 0] += 1
            } else {
                for tag in book.tags {
                    dict[tag.name, default: 0] += 1
                }
            }
        }
        return dict
            .map { CountItem(label: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    static func ratingHistogram(ratings: [Double]) -> [CountItem] {
        var bins = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        for r in ratings {
            let bucket = min(5, max(1, Int(r.rounded())))
            bins[bucket, default: 0] += 1
        }
        return (1...5).map { star in
            CountItem(label: "\(star)★", count: bins[star] ?? 0)
        }
    }

    static func pagesPerMonth(sessions: [ReadingSession], year: Int) -> [MonthPages] {
        let symbols = monthSymbols
        var totals = Array(repeating: 0, count: 12)
        for s in sessions {
            guard calendar.component(.year, from: s.date) == year else { continue }
            let m = calendar.component(.month, from: s.date)
            guard m >= 1, m <= 12 else { continue }
            totals[m - 1] += max(0, s.pagesRead)
        }
        return (1...12).map { m in
            let label = (m - 1) < symbols.count ? symbols[m - 1] : "\(m)"
            return MonthPages(monthIndex: m, label: label, pages: totals[m - 1])
        }
    }

    // MARK: - Streaks & day math

    /// Longest run of consecutive calendar days that each have at least one session.
    static func longestStreak(in dates: [Date]) -> Int {
        guard !dates.isEmpty else { return 0 }
        let days = Set(dates.map { calendar.startOfDay(for: $0) }).sorted()
        guard let first = days.first else { return 0 }
        var longest = 1
        var run = 1
        var previous = first
        for day in days.dropFirst() {
            let gap = calendar.dateComponents([.day], from: previous, to: day).day ?? 0
            if gap == 1 {
                run += 1
                longest = max(longest, run)
            } else if gap > 1 {
                run = 1
            }
            previous = day
        }
        return longest
    }

    static func distinctDayCount(_ dates: [Date]) -> Int {
        Set(dates.map { calendar.startOfDay(for: $0) }).count
    }

    // MARK: - "What next?" deterministic picker

    /// Deterministically picks one item from a list, seeded by a day-stable seed.
    /// Returns nil for an empty list (guarded indexing).
    static func dailyPick<T>(from items: [T], seed: Int) -> T? {
        guard !items.isEmpty else { return nil }
        let index = ((seed % items.count) + items.count) % items.count
        return items[index]
    }

    /// A day-stable seed (changes each calendar day).
    static func daySeed(_ date: Date = .now) -> Int {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 2026
        let m = comps.month ?? 1
        let d = comps.day ?? 1
        return y * 10_000 + m * 100 + d
    }
}
