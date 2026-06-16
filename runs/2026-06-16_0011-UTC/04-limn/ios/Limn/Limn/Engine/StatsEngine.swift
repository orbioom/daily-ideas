import Foundation

/// One bar in the "solved by size" chart.
struct SizeBucket: Identifiable {
    var id: Int { size }
    let size: Int
    let solved: Int
    let total: Int
    var sizeLabel: String { "\(size)×\(size)" }
}

/// One bar in the best-time distribution (grouped by minute band).
struct TimeBucket: Identifiable {
    var id: String { label }
    let label: String
    let count: Int
    let order: Int
}

/// Aggregated, derived statistics. Pure & testable.
struct StatsSummary {
    let totalSolved: Int
    let totalPuzzles: Int
    let totalSeconds: Int
    let bestTimeSeconds: Int
    let totalMistakes: Int
    let sizeBuckets: [SizeBucket]
    let timeBuckets: [TimeBucket]
    let currentStreak: Int
    let bestStreak: Int

    var isEmpty: Bool { totalSolved == 0 }

    var completionPercent: Int {
        guard totalPuzzles > 0 else { return 0 }
        return Int((Double(totalSolved) / Double(totalPuzzles) * 100).rounded())
    }

    var totalTimeLabel: String {
        let minutes = totalSeconds / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        let rem = minutes % 60
        return "\(hours)h \(rem)m"
    }

    var bestTimeLabel: String {
        guard bestTimeSeconds > 0 else { return "—" }
        let m = bestTimeSeconds / 60
        let s = bestTimeSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

enum StatsEngine {
    /// Builds a full summary from completed puzzle records and daily results.
    static func summarize(records: [PuzzleRecord],
                          dailies: [DailyResult],
                          calendar: Calendar = .current,
                          today: Date = Date()) -> StatsSummary {
        let solvedRecords = records.filter { $0.completed }
        let totalSolved = solvedRecords.count
        let totalSeconds = solvedRecords.reduce(0) { $0 + max(0, $1.bestTimeSeconds) }
        let bestTime = solvedRecords.compactMap { $0.bestTimeSeconds > 0 ? $0.bestTimeSeconds : nil }.min() ?? 0
        let totalMistakes = records.reduce(0) { $0 + max(0, $1.mistakes) }

        // Solved-by-size buckets across the whole bank.
        var solvedBySize: [Int: Int] = [:]
        let solvedIDs = Set(solvedRecords.map(\.puzzleID))
        for p in PuzzleBank.allPuzzles where solvedIDs.contains(p.id) {
            solvedBySize[p.rows, default: 0] += 1
        }
        var totalBySize: [Int: Int] = [:]
        for p in PuzzleBank.allPuzzles {
            totalBySize[p.rows, default: 0] += 1
        }
        let sizeBuckets = totalBySize.keys.sorted().map { size in
            SizeBucket(size: size, solved: solvedBySize[size] ?? 0, total: totalBySize[size] ?? 0)
        }

        // Best-time distribution by minute band.
        let bands: [(String, Int, ClosedRange<Int>)] = [
            ("<1m", 0, 0...59),
            ("1–3m", 1, 60...179),
            ("3–6m", 2, 180...359),
            ("6–10m", 3, 360...599),
            ("10m+", 4, 600...Int.max)
        ]
        var bandCounts: [Int: Int] = [:]
        for r in solvedRecords where r.bestTimeSeconds > 0 {
            for (_, order, range) in bands where range.contains(r.bestTimeSeconds) {
                bandCounts[order, default: 0] += 1
                break
            }
        }
        let timeBuckets = bands
            .map { TimeBucket(label: $0.0, count: bandCounts[$0.1] ?? 0, order: $0.1) }
            .filter { $0.count > 0 }

        let (current, best) = dailyStreaks(dailies: dailies, calendar: calendar, today: today)

        return StatsSummary(
            totalSolved: totalSolved,
            totalPuzzles: PuzzleBank.allPuzzles.count,
            totalSeconds: totalSeconds,
            bestTimeSeconds: bestTime,
            totalMistakes: totalMistakes,
            sizeBuckets: sizeBuckets,
            timeBuckets: timeBuckets,
            currentStreak: current,
            bestStreak: best
        )
    }

    /// Current and best daily streaks over completed `DailyResult`s.
    static func dailyStreaks(dailies: [DailyResult],
                             calendar: Calendar = .current,
                             today: Date = Date()) -> (current: Int, best: Int) {
        let completed = dailies.filter { $0.completed }
        let days: [Date] = completed.compactMap { result in
            dateFromKey(result.dateKey, calendar: calendar)
        }
        .map { calendar.startOfDay(for: $0) }
        let uniqueDays = Set(days).sorted()
        guard !uniqueDays.isEmpty else { return (0, 0) }

        // Best streak: longest run of consecutive days.
        var best = 1
        var run = 1
        if uniqueDays.count > 1 {
            for i in 1..<uniqueDays.count {
                let prev = uniqueDays[i - 1]
                let cur = uniqueDays[i]
                if let next = calendar.date(byAdding: .day, value: 1, to: prev),
                   calendar.isDate(next, inSameDayAs: cur) {
                    run += 1
                } else {
                    run = 1
                }
                best = max(best, run)
            }
        }

        // Current streak: walk back from today (or yesterday) while each day is present.
        let daySet = Set(uniqueDays)
        let startToday = calendar.startOfDay(for: today)
        var anchor: Date
        if daySet.contains(startToday) {
            anchor = startToday
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: startToday),
                  daySet.contains(yesterday) {
            anchor = yesterday
        } else {
            return (0, best)
        }
        var current = 0
        var cursor: Date? = anchor
        while let c = cursor, daySet.contains(c) {
            current += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: c)
        }
        return (current, best)
    }

    /// Parses a "yyyy-MM-dd" key back into a Date at the start of that day.
    static func dateFromKey(_ key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-")
        guard parts.count == 3,
              let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]) else { return nil }
        var comps = DateComponents()
        comps.year = y; comps.month = m; comps.day = d
        return calendar.date(from: comps)
    }
}
