import Foundation
import SwiftData

/// Pure, static analytics over a set of `Book`s and their `ReadingSession`s.
/// No SwiftData mutation, no UI — every function guards against empty inputs and
/// divide-by-zero so callers never crash on a fresh or sparse library.
enum MarginEngine {

    // MARK: - Types

    struct ChallengeProgress {
        let finished: Int        // books finished this year
        let target: Int          // yearly goal
        let fraction: Double     // finished / target, 0…1 (capped)
        let expected: Int        // books that "should" be done by now at even pace
        let pace: Int            // finished - expected (ahead if >0, behind if <0)
        let projected: Int       // projected year-end finishes at current rate
        let daysRemaining: Int   // days left in the year
        let dayOfYear: Int
        let daysInYear: Int

        /// "3 books ahead of schedule" style verdict.
        var verdict: String {
            guard target > 0 else { return "Set a goal to start your challenge." }
            if finished >= target { return "Goal reached — you did it!" }
            if pace > 0 { return "\(pace) book\(pace == 1 ? "" : "s") ahead of schedule" }
            if pace < 0 { return "\(-pace) book\(pace == -1 ? "" : "s") behind schedule" }
            return "Right on pace"
        }
    }

    struct MonthCount: Identifiable {
        let id = UUID()
        let month: Date          // first day of the month
        let count: Int
    }

    struct WeekPages: Identifiable {
        let id = UUID()
        let weekStart: Date
        let pages: Int
    }

    struct GenreSlice: Identifiable {
        let id = UUID()
        let genre: BookGenre
        let count: Int
        let fraction: Double
    }

    struct RatingBar: Identifiable {
        let id = UUID()
        let stars: Int           // 1…5
        let count: Int
    }

    // MARK: - Date helpers

    private static func dayOfYear(_ date: Date, cal: Calendar) -> Int {
        cal.ordinality(of: .day, in: .year, for: date) ?? 1
    }

    private static func daysInYear(_ date: Date, cal: Calendar) -> Int {
        guard let range = cal.range(of: .day, in: .year, for: date) else { return 365 }
        return range.count
    }

    /// Books with status finished and a finishedAt date inside the given year.
    static func finishedThisYear(_ books: [Book], now: Date = .now) -> [Book] {
        let cal = Calendar.current
        return books.filter {
            $0.status == .finished
            && ($0.finishedAt.map { cal.isDate($0, equalTo: now, toGranularity: .year) } ?? false)
        }
    }

    // MARK: - Yearly challenge

    static func challenge(_ books: [Book], target: Int, now: Date = .now) -> ChallengeProgress {
        let cal = Calendar.current
        let finishedBooks = finishedThisYear(books, now: now)
        let finished = finishedBooks.count
        let doy = dayOfYear(now, cal: cal)
        let diy = max(1, daysInYear(now, cal: cal))
        let safeTarget = max(0, target)

        let fraction: Double = safeTarget > 0 ? min(Double(finished) / Double(safeTarget), 1) : 0
        let expected = Int((Double(safeTarget) * (Double(doy) / Double(diy))).rounded())
        let pace = finished - expected

        // Project year-end finishes from the current per-day rate.
        let projected: Int
        if doy > 0 {
            let rate = Double(finished) / Double(doy)
            projected = Int((rate * Double(diy)).rounded())
        } else {
            projected = finished
        }
        let daysRemaining = max(0, diy - doy)

        return ChallengeProgress(finished: finished,
                                 target: safeTarget,
                                 fraction: fraction,
                                 expected: expected,
                                 pace: pace,
                                 projected: projected,
                                 daysRemaining: daysRemaining,
                                 dayOfYear: doy,
                                 daysInYear: diy)
    }

    // MARK: - All-time / yearly stats

    /// Total pages read across all logged sessions (all-time).
    static func totalPagesAllTime(_ books: [Book]) -> Int {
        books.reduce(0) { $0 + $1.sessions.reduce(0) { $0 + $1.pagesRead } }
    }

    /// Total pages read in sessions dated this calendar year.
    static func totalPagesThisYear(_ books: [Book], now: Date = .now) -> Int {
        let cal = Calendar.current
        return books.reduce(0) { acc, book in
            acc + book.sessions
                .filter { cal.isDate($0.date, equalTo: now, toGranularity: .year) }
                .reduce(0) { $0 + $1.pagesRead }
        }
    }

    static func booksFinishedAllTime(_ books: [Book]) -> Int {
        books.filter { $0.status == .finished }.count
    }

    /// Average rating across rated finished books (rating > 0), or nil if none.
    static func averageRating(_ books: [Book]) -> Double? {
        let rated = books.filter { $0.status == .finished && $0.rating > 0 }
        guard !rated.isEmpty else { return nil }
        return Double(rated.reduce(0) { $0 + $1.rating }) / Double(rated.count)
    }

    /// Average days-to-finish across finished books that have both dates.
    static func averageDaysToFinish(_ books: [Book]) -> Double? {
        let spans = books.compactMap { $0.daysToFinish }
        guard !spans.isEmpty else { return nil }
        return Double(spans.reduce(0, +)) / Double(spans.count)
    }

    /// The finished or in-progress book with the most pages.
    static func longestBook(_ books: [Book]) -> Book? {
        books.max { $0.totalPages < $1.totalPages }
    }

    /// Pages read per day averaged over the last `days` days.
    static func pagesPerDay(_ books: [Book], days: Int = 30, now: Date = .now) -> Double {
        guard days > 0 else { return 0 }
        let cal = Calendar.current
        guard let cutoff = cal.date(byAdding: .day, value: -days, to: cal.startOfDay(for: now)) else { return 0 }
        let pages = books.reduce(0) { acc, book in
            acc + book.sessions.filter { $0.date >= cutoff }.reduce(0) { $0 + $1.pagesRead }
        }
        return Double(pages) / Double(days)
    }

    /// Current reading streak: consecutive days up to today that have ≥1 session.
    static func currentStreak(_ books: [Book], now: Date = .now) -> Int {
        let cal = Calendar.current
        let sessionDays: Set<Date> = Set(
            books.flatMap { $0.sessions }.map { cal.startOfDay(for: $0.date) }
        )
        guard !sessionDays.isEmpty else { return 0 }

        var streak = 0
        var cursor = cal.startOfDay(for: now)
        // Allow the streak to "hold" if today has no session yet but yesterday did.
        if !sessionDays.contains(cursor) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            if sessionDays.contains(yesterday) {
                cursor = yesterday
            } else {
                return 0
            }
        }
        while sessionDays.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    // MARK: - Distributions

    /// Genre distribution across finished books (largest first).
    static func genreDistribution(_ books: [Book]) -> [GenreSlice] {
        let finished = books.filter { $0.status == .finished }
        guard !finished.isEmpty else { return [] }
        let total = Double(finished.count)
        let grouped = Dictionary(grouping: finished, by: { $0.genre }).mapValues(\.count)
        return grouped
            .map { GenreSlice(genre: $0.key, count: $0.value, fraction: Double($0.value) / total) }
            .sorted { $0.count > $1.count }
    }

    /// Rating distribution 1…5 across rated finished books (always 5 entries).
    static func ratingDistribution(_ books: [Book]) -> [RatingBar] {
        var buckets = Array(repeating: 0, count: 6) // index 1…5
        for b in books where b.status == .finished && b.rating > 0 {
            let r = min(max(b.rating, 1), 5)
            buckets[r] += 1
        }
        return (1...5).map { RatingBar(stars: $0, count: buckets[$0]) }
    }

    // MARK: - Series

    /// Books finished per month for the year `now` falls in (Jan…Dec, 12 points).
    static func booksFinishedPerMonth(_ books: [Book], now: Date = .now) -> [MonthCount] {
        let cal = Calendar.current
        guard let yearStart = cal.dateInterval(of: .year, for: now)?.start else { return [] }
        let finished = finishedThisYear(books, now: now)
        var out: [MonthCount] = []
        for m in 0..<12 {
            guard let monthStart = cal.date(byAdding: .month, value: m, to: yearStart) else { continue }
            let count = finished.filter {
                guard let f = $0.finishedAt else { return false }
                return cal.isDate(f, equalTo: monthStart, toGranularity: .month)
            }.count
            out.append(MonthCount(month: monthStart, count: count))
        }
        return out
    }

    /// Pages read per week over the last `weeks` weeks (oldest → newest).
    static func pagesPerWeek(_ books: [Book], weeks: Int = 12, now: Date = .now) -> [WeekPages] {
        let cal = Calendar.current
        guard let thisWeekStart = cal.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
        let sessions = books.flatMap { $0.sessions }
        var out: [WeekPages] = []
        for back in stride(from: weeks - 1, through: 0, by: -1) {
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: -back, to: thisWeekStart) else { continue }
            let pages = sessions
                .filter { cal.isDate($0.date, equalTo: weekStart, toGranularity: .weekOfYear) }
                .reduce(0) { $0 + $1.pagesRead }
            out.append(WeekPages(weekStart: weekStart, pages: pages))
        }
        return out
    }

    // MARK: - Per-book projection

    /// Projected finish date for an actively-reading book, from its recent
    /// session pace. Returns nil if there is no usable pace or no pages remain.
    static func projectedFinish(for book: Book, recentDays: Int = 30, now: Date = .now) -> Date? {
        guard book.pagesRemaining > 0 else { return nil }
        let cal = Calendar.current
        guard let cutoff = cal.date(byAdding: .day, value: -recentDays, to: cal.startOfDay(for: now)) else { return nil }
        let recentPages = book.sessions.filter { $0.date >= cutoff }.reduce(0) { $0 + $1.pagesRead }
        guard recentPages > 0, recentDays > 0 else { return nil }
        let perDay = Double(recentPages) / Double(recentDays)
        guard perDay > 0 else { return nil }
        let daysNeeded = Int((Double(book.pagesRemaining) / perDay).rounded(.up))
        guard daysNeeded > 0 else { return nil }
        return cal.date(byAdding: .day, value: daysNeeded, to: cal.startOfDay(for: now))
    }
}
