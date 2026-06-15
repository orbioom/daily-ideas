import Foundation

/// A single milestone badge. Progress is derived purely from game history.
struct Achievement: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    /// 0...1 toward unlocking. 1.0 = unlocked.
    let progress: Double
    /// Human-readable progress, e.g. "7 / 10".
    let progressLabel: String

    var unlocked: Bool { progress >= 1.0 }
}

/// Computes the full achievement set from completed games. Pure & testable.
enum AchievementEngine {
    /// Returns all achievements with current progress, given completed records.
    static func compute(records: [GameRecord]) -> [Achievement] {
        let games = records.count
        let bestTile = records.map(\.highestTile).max() ?? 0
        let bestScore = records.map(\.score).max() ?? 0
        let wins = records.filter(\.won).count

        func tileBadge(_ target: Int, symbol: String) -> Achievement {
            let progress = target <= 0 ? 1 : min(1.0, Double(bestTile) / Double(target))
            return Achievement(
                id: "tile_\(target)",
                title: "Reach \(target)",
                detail: "Merge your way to a \(target) tile.",
                symbol: symbol,
                progress: progress,
                progressLabel: bestTile >= target ? "Done" : "Best \(bestTile)"
            )
        }

        func gamesBadge(_ target: Int, symbol: String) -> Achievement {
            let progress = target <= 0 ? 1 : min(1.0, Double(games) / Double(target))
            return Achievement(
                id: "games_\(target)",
                title: "Play \(target) games",
                detail: "Finish \(target) games of any size.",
                symbol: symbol,
                progress: progress,
                progressLabel: "\(min(games, target)) / \(target)"
            )
        }

        func scoreBadge(_ target: Int, symbol: String) -> Achievement {
            let progress = target <= 0 ? 1 : min(1.0, Double(bestScore) / Double(target))
            return Achievement(
                id: "score_\(target)",
                title: "Score \(formatted(target))",
                detail: "Earn \(formatted(target)) points in a single game.",
                symbol: symbol,
                progress: progress,
                progressLabel: bestScore >= target ? "Done" : "Best \(formatted(bestScore))"
            )
        }

        let firstWin = Achievement(
            id: "first_win",
            title: "First 2048",
            detail: "Build your very first 2048 tile.",
            symbol: "trophy.fill",
            progress: wins > 0 ? 1 : min(1.0, Double(bestTile) / 2048.0),
            progressLabel: wins > 0 ? "Done" : "Best \(bestTile)"
        )

        return [
            tileBadge(128, symbol: "1.square.fill"),
            tileBadge(256, symbol: "2.square.fill"),
            tileBadge(512, symbol: "5.square.fill"),
            tileBadge(1024, symbol: "square.stack.3d.up.fill"),
            tileBadge(2048, symbol: "star.fill"),
            tileBadge(4096, symbol: "crown.fill"),
            firstWin,
            gamesBadge(10, symbol: "gamecontroller.fill"),
            gamesBadge(50, symbol: "flame.fill"),
            gamesBadge(100, symbol: "bolt.fill"),
            scoreBadge(5_000, symbol: "chart.line.uptrend.xyaxis"),
            scoreBadge(10_000, symbol: "rosette"),
            scoreBadge(20_000, symbol: "medal.fill")
        ]
    }

    static func formatted(_ n: Int) -> String {
        if n >= 1000 {
            let k = Double(n) / 1000.0
            return k == k.rounded() ? "\(Int(k))k" : String(format: "%.1fk", k)
        }
        return "\(n)"
    }
}
