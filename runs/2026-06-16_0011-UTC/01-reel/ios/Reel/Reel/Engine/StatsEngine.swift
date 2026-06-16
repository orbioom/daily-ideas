import Foundation

// MARK: - Result value types (Identifiable for Charts)

struct CountSlice: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
}

struct RatingBin: Identifiable {
    let id = UUID()
    /// Star value 0.5 ... 5.0 in half steps.
    let stars: Double
    let count: Int
    var label: String {
        // "3" or "3.5"
        stars == stars.rounded() ? String(Int(stars)) : String(format: "%.1f", stars)
    }
}

struct MonthCount: Identifiable {
    let id = UUID()
    let monthIndex: Int      // 1...12
    let count: Int
    var label: String {
        let symbols = DateFormatter().shortMonthSymbols ?? []
        let i = monthIndex - 1
        guard i >= 0, i < symbols.count else { return "\(monthIndex)" }
        return symbols[i]
    }
}

struct StatsResult {
    var totalWatched = 0
    var totalHours = 0.0
    var filmCount = 0
    var showCount = 0
    var averageRating = 0.0
    var thisYearCount = 0
    var longestStreak = 0
    var genreCounts: [CountSlice] = []
    var decadeCounts: [CountSlice] = []
    var ratingHistogram: [RatingBin] = []
    var topGenres: [CountSlice] = []
    var monthCounts: [MonthCount] = []

    var isEmpty: Bool { totalWatched == 0 && filmCount == 0 && showCount == 0 }
}

/// Pure, fully-guarded statistics over a Title collection and its diary entries.
enum StatsEngine {

    static func compute(titles: [Title], year: Int) -> StatsResult {
        var result = StatsResult()

        // "Watched" universe: anything marked watched, plus shows currently watching with progress.
        let counted = titles.filter { $0.status == .watched }
        result.totalWatched = counted.count

        // Films vs shows (among counted).
        result.filmCount = counted.filter { !$0.kind.isShow }.count
        result.showCount = counted.filter { $0.kind.isShow }.count

        // Total hours: sum watchedMinutes across ALL titles (shows accrue as you watch).
        let totalMinutes = titles.reduce(0) { $0 + $1.watchedMinutes }
        result.totalHours = (Double(totalMinutes) / 60.0 * 10).rounded() / 10

        // Average rating over titles that have a rating.
        let rated = titles.compactMap { $0.rating }.filter { $0 > 0 }
        if !rated.isEmpty {
            let sum = rated.reduce(0, +)
            result.averageRating = (sum / Double(rated.count) * 100).rounded() / 100
        }

        // Genre counts (over watched titles).
        var genreMap: [String: Int] = [:]
        for t in counted {
            for g in t.genres { genreMap[g.rawValue, default: 0] += 1 }
        }
        result.genreCounts = genreMap
            .map { CountSlice(label: $0.key, count: $0.value) }
            .sorted { $0.count == $1.count ? $0.label < $1.label : $0.count > $1.count }
        result.topGenres = Array(result.genreCounts.prefix(5))

        // Decade counts (over watched titles, guard year sanity).
        var decadeMap: [String: Int] = [:]
        for t in counted where t.year > 1800 && t.year < 2200 {
            decadeMap[t.decadeLabel, default: 0] += 1
        }
        result.decadeCounts = decadeMap
            .map { CountSlice(label: $0.key, count: $0.value) }
            .sorted { $0.label < $1.label }

        // Ratings histogram 0.5...5.0 (over titles with a rating).
        var ratingMap: [Double: Int] = [:]
        for t in titles {
            guard let r = t.rating, r >= 0.5 else { continue }
            // Snap to nearest half-step within bounds.
            let snapped = min(5.0, max(0.5, (r * 2).rounded() / 2))
            ratingMap[snapped, default: 0] += 1
        }
        result.ratingHistogram = stride(from: 0.5, through: 5.0, by: 0.5).map { stars in
            RatingBin(stars: stars, count: ratingMap[stars] ?? 0)
        }

        // This-year watched count (by diary entries dated in `year`, plus films marked watched this year).
        let cal = Calendar.current
        var thisYear = 0
        var diaryDates: [Date] = []
        for t in titles {
            for e in t.entries {
                diaryDates.append(e.watchedDate)
                if cal.component(.year, from: e.watchedDate) == year { thisYear += 1 }
            }
        }
        result.thisYearCount = thisYear

        // Per-month counts for `year` from diary dates.
        var monthMap: [Int: Int] = [:]
        for d in diaryDates where cal.component(.year, from: d) == year {
            let m = cal.component(.month, from: d)
            monthMap[m, default: 0] += 1
        }
        result.monthCounts = (1...12).map { MonthCount(monthIndex: $0, count: monthMap[$0] ?? 0) }

        // Longest consecutive-day logging streak across ALL diary dates.
        result.longestStreak = longestConsecutiveDayStreak(dates: diaryDates, calendar: cal)

        return result
    }

    /// Longest run of consecutive calendar days that have at least one diary entry.
    static func longestConsecutiveDayStreak(dates: [Date], calendar: Calendar) -> Int {
        guard !dates.isEmpty else { return 0 }
        // Reduce to a sorted set of unique day-start timestamps.
        let days = Set(dates.map { calendar.startOfDay(for: $0) }).sorted()
        guard let first = days.first else { return 0 }

        var longest = 1
        var current = 1
        var previous = first
        for day in days.dropFirst() {
            // Days between previous and this day.
            let comps = calendar.dateComponents([.day], from: previous, to: day)
            let gap = comps.day ?? 0
            if gap == 1 {
                current += 1
                longest = max(longest, current)
            } else if gap > 1 {
                current = 1
            }
            // gap == 0 shouldn't occur after de-duping, but is harmless.
            previous = day
        }
        return longest
    }
}
