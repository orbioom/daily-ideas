import Foundation

/// Pure computations over a set of episodes for the Insights screen.
/// Stateless and side-effect-free; instantiate with the current episodes.
struct StatsEngine {
    let episodes: [PanicEpisode]
    private let calendar = Calendar.current
    private let now: Date

    init(episodes: [PanicEpisode], now: Date = .now) {
        self.episodes = episodes
        self.now = now
    }

    var hasData: Bool { !episodes.isEmpty }

    // MARK: - Headline numbers

    /// Days since the most recent episode (0 if one happened today).
    var daysSinceLast: Int? {
        guard let last = episodes.map(\.startedAt).max() else { return nil }
        let startOfLast = calendar.startOfDay(for: last)
        let startOfNow = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: startOfLast, to: startOfNow).day ?? 0
        return max(0, days)
    }

    /// Current streak of consecutive days WITHOUT a logged episode, counting back
    /// from today. If an episode happened today, the streak is 0.
    var currentStreak: Int {
        let episodeDays = Set(episodes.map { calendar.startOfDay(for: $0.startedAt) })
        var streak = 0
        var day = calendar.startOfDay(for: now)
        while !episodeDays.contains(day) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
            if streak > 3650 { break } // safety bound
        }
        return streak
    }

    /// Average intensity-before across all episodes.
    var averageIntensityBefore: Double? {
        guard !episodes.isEmpty else { return nil }
        let total = episodes.reduce(0) { $0 + $1.intensityBefore }
        return Double(total) / Double(episodes.count)
    }

    /// Average intensity DROP (before − after) over episodes that recorded an after.
    var averageIntensityDrop: Double? {
        let drops = episodes.compactMap { $0.intensityDrop }
        guard !drops.isEmpty else { return nil }
        return Double(drops.reduce(0, +)) / Double(drops.count)
    }

    // MARK: - Time series

    struct WeekBucket: Identifiable {
        let id = UUID()
        let weekStart: Date
        let count: Int
        var label: String {
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            return f.string(from: weekStart)
        }
    }

    /// Episodes per week for the last `weeks` weeks (oldest → newest).
    func episodesPerWeek(weeks: Int = 8) -> [WeekBucket] {
        guard weeks > 0 else { return [] }
        let startOfThisWeek = startOfWeek(for: now)
        var buckets: [WeekBucket] = []
        for offset in stride(from: weeks - 1, through: 0, by: -1) {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -offset, to: startOfThisWeek) else { continue }
            guard let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { continue }
            let count = episodes.filter { $0.startedAt >= weekStart && $0.startedAt < weekEnd }.count
            buckets.append(WeekBucket(weekStart: weekStart, count: count))
        }
        return buckets
    }

    private func startOfWeek(for date: Date) -> Date {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: comps) ?? calendar.startOfDay(for: date)
    }

    // MARK: - Triggers

    struct RankedItem: Identifiable {
        let id = UUID()
        let name: String
        let count: Int
    }

    /// Top triggers ranked by frequency across all episodes.
    func topTriggers(limit: Int = 6) -> [RankedItem] {
        var counts: [String: Int] = [:]
        for ep in episodes {
            for t in ep.triggers {
                counts[t.name, default: 0] += 1
            }
        }
        return rank(counts, limit: limit)
    }

    /// "What helped" ranking, counted across episodes' helpedBy lists.
    func whatHelped(limit: Int = 6) -> [RankedItem] {
        var counts: [String: Int] = [:]
        for ep in episodes {
            for name in ep.helpedBy {
                counts[name, default: 0] += 1
            }
        }
        return rank(counts, limit: limit)
    }

    private func rank(_ counts: [String: Int], limit: Int) -> [RankedItem] {
        counts
            .map { RankedItem(name: $0.key, count: $0.value) }
            .sorted { ($0.count, $1.name) > ($1.count, $0.name) }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Time of day

    enum DayPart: String, CaseIterable, Identifiable {
        case night, morning, afternoon, evening
        var id: String { rawValue }
        var label: String {
            switch self {
            case .night: return "Night"
            case .morning: return "Morning"
            case .afternoon: return "Afternoon"
            case .evening: return "Evening"
            }
        }
        var range: String {
            switch self {
            case .night: return "12–6am"
            case .morning: return "6am–12pm"
            case .afternoon: return "12–6pm"
            case .evening: return "6pm–12am"
            }
        }
    }

    struct DayPartCount: Identifiable {
        let id = UUID()
        let part: DayPart
        let count: Int
    }

    func timeOfDayDistribution() -> [DayPartCount] {
        var counts: [DayPart: Int] = [:]
        for ep in episodes {
            let hour = calendar.component(.hour, from: ep.startedAt)
            let part: DayPart
            switch hour {
            case 0..<6: part = .night
            case 6..<12: part = .morning
            case 12..<18: part = .afternoon
            default: part = .evening
            }
            counts[part, default: 0] += 1
        }
        return DayPart.allCases.map { DayPartCount(part: $0, count: counts[$0] ?? 0) }
    }

    // MARK: - Period counts

    func countThisWeek() -> Int {
        let start = startOfWeek(for: now)
        return episodes.filter { $0.startedAt >= start }.count
    }

    func countThisMonth() -> Int {
        let comps = calendar.dateComponents([.year, .month], from: now)
        guard let start = calendar.date(from: comps) else { return 0 }
        return episodes.filter { $0.startedAt >= start }.count
    }
}
