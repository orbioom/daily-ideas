import Foundation

/// A Sendable snapshot of a GameResult so stats can be computed off the main actor.
struct ResultLite: Sendable {
    let date: Date
    let score: Int
    let linesCleared: Int
    let piecesPlaced: Int
    let longestCombo: Int
    let modeRaw: String
}

/// One bucket in the score distribution histogram (Identifiable for Charts).
struct ScoreBucket: Identifiable, Sendable {
    let id: Int
    let lower: Int
    let upper: Int
    let count: Int
    var label: String { "\(lower)" }
}

/// One point in the score-over-time series.
struct ScorePoint: Identifiable, Sendable {
    let id: Int
    let index: Int
    let date: Date
    let score: Int
}

/// One point in the lines-per-game series.
struct LinesPoint: Identifiable, Sendable {
    let id: Int
    let index: Int
    let score: Int
    let lines: Int
}

/// All computed stats for the Stats screen. Built off the main actor from `ResultLite`s.
struct StatsSummary: Sendable {
    let totalGames: Int
    let bestScore: Int
    let averageScore: Int
    let totalLines: Int
    let longestCombo: Int
    let totalPieces: Int

    let distribution: [ScoreBucket]
    let overTime: [ScorePoint]
    let linesPerGame: [LinesPoint]

    static func build(from results: [ResultLite]) -> StatsSummary {
        guard !results.isEmpty else {
            return StatsSummary(totalGames: 0, bestScore: 0, averageScore: 0,
                                totalLines: 0, longestCombo: 0, totalPieces: 0,
                                distribution: [], overTime: [], linesPerGame: [])
        }

        let scores = results.map(\.score)
        let total = results.count
        let best = scores.max() ?? 0
        let sum = scores.reduce(0, +)
        let avg = total > 0 ? sum / total : 0
        let lines = results.reduce(0) { $0 + $1.linesCleared }
        let combo = results.map(\.longestCombo).max() ?? 0
        let pieces = results.reduce(0) { $0 + $1.piecesPlaced }

        // Distribution: 8 buckets across the score range.
        let bucketCount = 8
        let maxScore = max(best, 1)
        let width = max(1, Int(ceil(Double(maxScore + 1) / Double(bucketCount))))
        var counts = [Int](repeating: 0, count: bucketCount)
        for s in scores {
            let idx = min(bucketCount - 1, max(0, s / width))
            counts[idx] += 1
        }
        let distribution = (0..<bucketCount).map { i in
            ScoreBucket(id: i, lower: i * width, upper: (i + 1) * width, count: counts[i])
        }

        // Over time: chronological, most-recent-last.
        let chronological = results.sorted { $0.date < $1.date }
        let overTime = chronological.enumerated().map { i, r in
            ScorePoint(id: i, index: i, date: r.date, score: r.score)
        }

        // Lines per game: last up-to-20 games, recency first then reversed for display.
        let recent = Array(chronological.suffix(20))
        let linesPerGame = recent.enumerated().map { i, r in
            LinesPoint(id: i, index: i, score: r.score, lines: r.linesCleared)
        }

        return StatsSummary(totalGames: total,
                            bestScore: best,
                            averageScore: avg,
                            totalLines: lines,
                            longestCombo: combo,
                            totalPieces: pieces,
                            distribution: distribution,
                            overTime: overTime,
                            linesPerGame: linesPerGame)
    }
}
