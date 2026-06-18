import Foundation

struct MonthCount: Identifiable {
    let id: String          // "yyyy-MM"
    let date: Date          // first of month
    let label: String       // "Apr"
    let count: Int
}

struct MoodSlice: Identifiable {
    let id: Int
    let mood: Mood
    let count: Int
}

struct TagCount: Identifiable {
    var id: String { tag }
    let tag: String
    let count: Int
}

struct StatsSummary {
    var totalMoments: Int
    var photoCount: Int
    var distinctDays: Int
    var longestStreak: Int
    var monthCounts: [MonthCount]
    var moodSlices: [MoodSlice]
    var topTags: [TagCount]
    var favoriteCount: Int
}

/// Pure analytics over a moment list. No SwiftData, no UI.
enum StatsEngine {
    static func summary(moments: [Moment], calendar: Calendar = .current) -> StatsSummary {
        let total = moments.count
        let photos = moments.filter { ($0.imageFilename?.isEmpty == false) }.count
        let days = Set(moments.map { $0.dayKey }).count
        let favorites = moments.filter { $0.isFavorite }.count
        let longest = StreakEngine.longestStreak(keys: Set(moments.map { $0.dayKey }))

        return StatsSummary(
            totalMoments: total,
            photoCount: photos,
            distinctDays: days,
            longestStreak: longest,
            monthCounts: monthCounts(moments: moments, calendar: calendar),
            moodSlices: moodSlices(moments: moments),
            topTags: topTags(moments: moments, limit: 6),
            favoriteCount: favorites
        )
    }

    /// Moments per month for the last `span` months (oldest → newest).
    static func monthCounts(moments: [Moment], span: Int = 6, calendar: Calendar = .current, today: Date = Date()) -> [MonthCount] {
        let formatterKey = DateFormatter()
        formatterKey.calendar = calendar
        formatterKey.locale = Locale(identifier: "en_US_POSIX")
        formatterKey.dateFormat = "yyyy-MM"

        let formatterLabel = DateFormatter()
        formatterLabel.calendar = calendar
        formatterLabel.dateFormat = "MMM"

        // Pre-count per month key.
        var counts: [String: Int] = [:]
        for moment in moments {
            let key = formatterKey.string(from: moment.displayDate)
            counts[key, default: 0] += 1
        }

        var result: [MonthCount] = []
        let startOfThisMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today
        for offset in stride(from: span - 1, through: 0, by: -1) {
            guard let monthDate = calendar.date(byAdding: .month, value: -offset, to: startOfThisMonth) else { continue }
            let key = formatterKey.string(from: monthDate)
            result.append(MonthCount(
                id: key,
                date: monthDate,
                label: formatterLabel.string(from: monthDate),
                count: counts[key] ?? 0
            ))
        }
        return result
    }

    static func moodSlices(moments: [Moment]) -> [MoodSlice] {
        var counts: [Int: Int] = [:]
        for moment in moments { counts[moment.moodRaw, default: 0] += 1 }
        return Mood.allCases.map { mood in
            MoodSlice(id: mood.rawValue, mood: mood, count: counts[mood.rawValue] ?? 0)
        }
        .filter { $0.count > 0 }
    }

    static func topTags(moments: [Moment], limit: Int) -> [TagCount] {
        var counts: [String: Int] = [:]
        for moment in moments {
            for tag in moment.tags {
                let clean = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard !clean.isEmpty else { continue }
                counts[clean, default: 0] += 1
            }
        }
        return counts
            .map { TagCount(tag: $0.key, count: $0.value) }
            .sorted { lhs, rhs in
                lhs.count == rhs.count ? lhs.tag < rhs.tag : lhs.count > rhs.count
            }
            .prefix(limit)
            .map { $0 }
    }
}
