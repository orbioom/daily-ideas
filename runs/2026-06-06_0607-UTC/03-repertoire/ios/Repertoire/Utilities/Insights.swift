import Foundation

/// Pure, testable aggregation over sessions and pieces. No SwiftData fetching here —
/// callers pass in the already-queried arrays so this stays a deterministic function
/// of its inputs (and `#Preview`-friendly).
enum Insights {

    private static var calendar: Calendar {
        var c = Calendar.current
        c.firstWeekday = 2  // Monday-led weeks read naturally for practice habits.
        return c
    }

    // MARK: - Per-day minutes

    /// Total practiced minutes on a given calendar day.
    static func minutes(on day: Date, sessions: [PracticeSession]) -> Int {
        let cal = calendar
        return sessions
            .filter { cal.isDate($0.date, inSameDayAs: day) }
            .reduce(0) { $0 + $1.minutes }
    }

    /// Minutes for each of the last `days` calendar days, oldest-first.
    /// Each tuple is (start-of-day, minutes).
    static func dailyMinutes(sessions: [PracticeSession],
                             days: Int = 7,
                             ending: Date = .now) -> [(day: Date, minutes: Int)] {
        let cal = calendar
        let count = max(1, days)
        let today = cal.startOfDay(for: ending)
        var result: [(Date, Int)] = []
        for offset in stride(from: count - 1, through: 0, by: -1) {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            result.append((day, minutes(on: day, sessions: sessions)))
        }
        return result
    }

    /// A 7-column × `weeks`-row grid of minutes for a heatmap, most recent week last.
    /// Each row is Monday→Sunday. The grid always covers full weeks ending today's week.
    static func weeklyHeatmap(sessions: [PracticeSession],
                              weeks: Int = 6,
                              ending: Date = .now) -> [[(day: Date, minutes: Int)]] {
        let cal = calendar
        let weekCount = max(1, weeks)
        let today = cal.startOfDay(for: ending)
        // Find the Monday of the current week.
        let weekday = cal.component(.weekday, from: today)
        // Days since Monday (firstWeekday = 2). weekday: 1=Sun…7=Sat.
        let daysFromMonday = (weekday + 5) % 7
        guard let thisMonday = cal.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return []
        }
        var rows: [[(Date, Int)]] = []
        for w in stride(from: weekCount - 1, through: 0, by: -1) {
            guard let weekStart = cal.date(byAdding: .day, value: -7 * w, to: thisMonday) else { continue }
            var row: [(Date, Int)] = []
            for d in 0..<7 {
                guard let day = cal.date(byAdding: .day, value: d, to: weekStart) else { continue }
                // Future days in the current week show zero rather than fabricated time.
                let mins = day > today ? 0 : minutes(on: day, sessions: sessions)
                row.append((day, mins))
            }
            rows.append(row)
        }
        return rows
    }

    /// Total minutes in the calendar week containing `reference`.
    static func minutesThisWeek(sessions: [PracticeSession], reference: Date = .now) -> Int {
        let cal = calendar
        guard let interval = cal.dateInterval(of: .weekOfYear, for: reference) else { return 0 }
        return sessions
            .filter { interval.contains($0.date) }
            .reduce(0) { $0 + $1.minutes }
    }

    // MARK: - Streaks

    /// Set of distinct practice days (start-of-day) present in the sessions.
    private static func practiceDays(_ sessions: [PracticeSession]) -> Set<Date> {
        let cal = calendar
        return Set(sessions.map { cal.startOfDay(for: $0.date) })
    }

    /// Current consecutive-day streak ending today or yesterday (so a not-yet-practiced
    /// today doesn't break a live streak). Zero if neither day has practice.
    static func currentStreak(sessions: [PracticeSession], today: Date = .now) -> Int {
        let cal = calendar
        let days = practiceDays(sessions)
        guard !days.isEmpty else { return 0 }
        let start = cal.startOfDay(for: today)

        // Anchor: today if practiced, else yesterday if practiced, else no streak.
        var cursor: Date
        if days.contains(start) {
            cursor = start
        } else if let yesterday = cal.date(byAdding: .day, value: -1, to: start),
                  days.contains(yesterday) {
            cursor = yesterday
        } else {
            return 0
        }

        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    /// Longest consecutive-day streak anywhere in the history.
    static func longestStreak(sessions: [PracticeSession]) -> Int {
        let cal = calendar
        let days = practiceDays(sessions).sorted()
        guard !days.isEmpty else { return 0 }
        var longest = 1
        var run = 1
        for i in 1..<days.count {
            if let next = cal.date(byAdding: .day, value: 1, to: days[i - 1]),
               cal.isDate(next, inSameDayAs: days[i]) {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
        }
        return longest
    }

    // MARK: - Per-piece time

    /// Minutes attributed to each piece across all sessions, descending.
    /// Only pieces with recorded time appear.
    static func timeByPiece(pieces: [Piece]) -> [(piece: Piece, minutes: Int)] {
        pieces
            .map { piece in
                let mins = piece.entries.reduce(0) { $0 + $1.minutes }
                return (piece, mins)
            }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
    }

    /// Total recorded practice minutes across every session.
    static func totalMinutes(sessions: [PracticeSession]) -> Int {
        sessions.reduce(0) { $0 + $1.minutes }
    }

    // MARK: - Suggested next

    /// The active piece least recently practiced (never-practiced pieces sort first).
    /// Retired pieces are excluded. Nil when there are no eligible pieces.
    static func suggestedNext(pieces: [Piece], now: Date = .now) -> Piece? {
        let eligible = pieces.filter { $0.status.isActive }
        guard !eligible.isEmpty else { return nil }
        return eligible.min { a, b in
            // A nil lastPracticed (never practiced) is the most overdue → sorts first.
            let aDate = a.lastPracticed ?? .distantPast
            let bDate = b.lastPracticed ?? .distantPast
            if aDate == bDate {
                // Tie-break by creation so ordering is stable.
                return a.createdAt < b.createdAt
            }
            return aDate < bDate
        }
    }

    /// A human "last practiced" phrase for a piece.
    static func lastPracticedPhrase(_ piece: Piece, now: Date = .now) -> String {
        guard let date = piece.lastPracticed else { return "Not yet practiced" }
        let cal = calendar
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: date),
                                      to: cal.startOfDay(for: now)).day ?? 0
        switch days {
        case ..<0:  return "Practiced"
        case 0:     return "Practiced today"
        case 1:     return "Practiced yesterday"
        case 2...6: return "Practiced \(days) days ago"
        case 7...13: return "Practiced last week"
        default:    return "Practiced \(days / 7) weeks ago"
        }
    }
}
