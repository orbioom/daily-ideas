import Foundation
import SwiftData

@Observable
final class StatsViewModel {
    var records: [GameRecord] = []

    func load(from records: [GameRecord]) {
        self.records = records
    }

    var totalGames: Int { records.count }
    var wins: Int { records.filter { $0.playerWon }.count }
    var losses: Int { records.filter { !$0.playerWon && !$0.isDraw }.count }
    var draws: Int { records.filter { $0.isDraw }.count }
    var winRate: Double { totalGames > 0 ? Double(wins) / Double(totalGames) : 0 }

    var byDifficulty: [(String, Int, Int)] {
        let difficulties = ["beginner","intermediate","advanced"]
        return difficulties.compactMap { diff in
            let subset = records.filter { $0.difficulty == diff }
            guard !subset.isEmpty else { return nil }
            let w = subset.filter { $0.playerWon }.count
            return (diff, w, subset.count)
        }
    }

    var recentResults: [GameRecord] { Array(records.sorted { $0.date > $1.date }.prefix(30)) }
}
