import Foundation

/// Derives aggregate statistics from a list of `GameRecord`s. Pure & total.
struct StatsEngine {
    let records: [GameRecord]

    var gamesPlayed: Int { records.count }

    var bestScore: Int { records.map { $0.myScore }.max() ?? 0 }

    var averageScore: Double {
        guard !records.isEmpty else { return 0 }
        let total = records.reduce(0) { $0 + $1.myScore }
        return Double(total) / Double(records.count)
    }

    var totalYahtzees: Int { records.reduce(0) { $0 + $1.myYahtzees } }

    /// Win-rate against CPU only (the meaningful competitive metric).
    var cpuGames: [GameRecord] { records.filter { $0.mode == .vsCPU } }

    var cpuWinRate: Double {
        let games = cpuGames
        guard !games.isEmpty else { return 0 }
        let wins = games.filter { $0.didWin }.count
        return Double(wins) / Double(games.count)
    }

    var cpuWins: Int { cpuGames.filter { $0.didWin }.count }

    /// Average score per category across all recorded games where the category was played.
    func averageByCategory() -> [(category: ScoreCategory, average: Double, count: Int)] {
        var sums: [ScoreCategory: Int] = [:]
        var counts: [ScoreCategory: Int] = [:]
        for record in records {
            for (cat, value) in record.myCategoryScores {
                sums[cat, default: 0] += value
                counts[cat, default: 0] += 1
            }
        }
        return ScoreCategory.allCases.map { cat in
            let c = counts[cat] ?? 0
            let avg = c > 0 ? Double(sums[cat] ?? 0) / Double(c) : 0
            return (cat, avg, c)
        }
    }

    /// Score distribution bucketed into ranges for a histogram.
    func scoreDistribution(bucketSize: Int = 30) -> [(label: String, count: Int, lowerBound: Int)] {
        guard !records.isEmpty else { return [] }
        let scores = records.map { $0.myScore }
        let maxScore = scores.max() ?? 0
        let topBucket = (maxScore / bucketSize) + 1
        var buckets = [Int](repeating: 0, count: max(topBucket, 1))
        for s in scores {
            let idx = min(s / bucketSize, buckets.count - 1)
            if buckets.indices.contains(idx) { buckets[idx] += 1 }
        }
        return buckets.enumerated().map { idx, count in
            let lower = idx * bucketSize
            return ("\(lower)–\(lower + bucketSize - 1)", count, lower)
        }
    }

    /// Recent scores (chronological) for a trend line, oldest first.
    func recentScores(limit: Int = 20) -> [(date: Date, score: Int)] {
        records
            .sorted { $0.date < $1.date }
            .suffix(limit)
            .map { ($0.date, $0.myScore) }
    }

    var modeBreakdown: [(mode: GameMode, count: Int)] {
        GameMode.allCases.map { mode in
            (mode, records.filter { $0.mode == mode }.count)
        }.filter { $0.count > 0 }
    }
}
