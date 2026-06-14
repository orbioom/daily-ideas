import Foundation

/// A labelled count for a bar/category chart.
struct StatCategory: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
}

/// One bin of the 1–10 score histogram.
struct ScoreBin: Identifiable {
    let id = UUID()
    let score: Int          // 1...10
    let count: Int
    var label: String { "\(score)" }
}

/// A status slice for the donut.
struct StatusSlice: Identifiable {
    let id = UUID()
    let status: WatchStatus
    let kindForLabel: AnimeMediaKind
    let count: Int
    var label: String { status.label(for: kindForLabel) }
}

/// Completed titles in a given calendar month.
struct MonthCount: Identifiable {
    let id = UUID()
    let date: Date          // first of the month
    let count: Int
    var label: String {
        date.formatted(.dateTime.month(.abbreviated))
    }
}

/// Full computed snapshot for the Stats screen.
struct StatsResult {
    var totalTitles: Int = 0
    var animeCount: Int = 0
    var mangaCount: Int = 0
    var completedCount: Int = 0
    var episodesWatched: Int = 0
    var chaptersRead: Int = 0
    var minutesSpent: Int = 0
    var meanScore: Double = 0       // rated only
    var ratedCount: Int = 0
    var completionRate: Double = 0  // completed / total, 0...1
    var statusSlices: [StatusSlice] = []
    var scoreHistogram: [ScoreBin] = []
    var topGenres: [StatCategory] = []
    var completedPerMonth: [MonthCount] = []

    var isEmpty: Bool { totalTitles == 0 }
}

/// Pure, guarded statistics over the library.
enum StatsEngine {

    static func compute(titles: [Title], referenceDate: Date = .now) -> StatsResult {
        var r = StatsResult()
        r.totalTitles = titles.count
        guard !titles.isEmpty else { return r }

        r.animeCount = titles.filter { $0.kind == .anime }.count
        r.mangaCount = titles.filter { $0.kind == .manga }.count

        // Progress totals split by kind.
        for t in titles {
            let done = clampedProgress(t)
            switch t.kind {
            case .anime: r.episodesWatched += done
            case .manga: r.chaptersRead += done
            }
        }
        // Time spent ≈ 24 min/episode, 5 min/chapter, plus rewatches.
        for t in titles {
            let base = clampedProgress(t) * t.kind.minutesPerUnit
            let rewatch = (t.totalUnits ?? clampedProgress(t)) * t.kind.minutesPerUnit * max(0, t.rewatchCount)
            r.minutesSpent += base + rewatch
        }

        // Mean score over rated titles only.
        let rated = titles.filter { $0.score > 0 }
        r.ratedCount = rated.count
        if !rated.isEmpty {
            let sum = rated.reduce(0) { $0 + $1.score }
            r.meanScore = (Double(sum) / Double(rated.count) * 10).rounded() / 10
        }

        // Completion rate.
        r.completedCount = titles.filter { $0.status == .completed }.count
        r.completionRate = Double(r.completedCount) / Double(titles.count)

        // Status donut.
        var statusMap: [WatchStatus: Int] = [:]
        for t in titles { statusMap[t.status, default: 0] += 1 }
        // Use anime label as the canonical donut label when mixed.
        r.statusSlices = WatchStatus.allCases.compactMap { st in
            let c = statusMap[st] ?? 0
            guard c > 0 else { return nil }
            return StatusSlice(status: st, kindForLabel: .anime, count: c)
        }

        // Score histogram, 1...10.
        var bins = Array(repeating: 0, count: 11)   // index 0 unused
        for t in titles where t.score >= 1 && t.score <= 10 {
            bins[t.score] += 1
        }
        r.scoreHistogram = (1...10).map { ScoreBin(score: $0, count: bins[$0]) }

        // Genre distribution (top by count).
        var genreMap: [String: Int] = [:]
        for t in titles {
            for g in t.genres {
                let key = g.name.trimmingCharacters(in: .whitespaces)
                guard !key.isEmpty else { continue }
                genreMap[key, default: 0] += 1
            }
        }
        r.topGenres = genreMap
            .map { StatCategory(label: $0.key, count: $0.value) }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.label < rhs.label
            }

        // Completed per month over the trailing 12 months.
        r.completedPerMonth = completionsByMonth(titles: titles, referenceDate: referenceDate)

        return r
    }

    /// Trailing-12-month completion counts (oldest → newest), every month present.
    static func completionsByMonth(titles: [Title], referenceDate: Date) -> [MonthCount] {
        let cal = Calendar.current
        guard let startOfThisMonth = cal.date(from: cal.dateComponents([.year, .month], from: referenceDate)) else {
            return []
        }
        // Build the 12 month buckets.
        var months: [Date] = []
        for back in stride(from: 11, through: 0, by: -1) {
            if let d = cal.date(byAdding: .month, value: -back, to: startOfThisMonth) {
                months.append(d)
            }
        }
        var counts: [Date: Int] = [:]
        for t in titles {
            guard t.status == .completed, let finished = t.finishedAt else { continue }
            guard let bucket = cal.date(from: cal.dateComponents([.year, .month], from: finished)) else { continue }
            if months.contains(bucket) {
                counts[bucket, default: 0] += 1
            }
        }
        return months.map { MonthCount(date: $0, count: counts[$0] ?? 0) }
    }

    /// Progress clamped to the title's total when known.
    private static func clampedProgress(_ t: Title) -> Int {
        let p = max(0, t.progress)
        if let total = t.totalUnits, total > 0 { return min(p, total) }
        return p
    }
}
