import SwiftData
import Foundation

@Model
final class DraughtsStats {
    var gamesPlayed: Int = 0
    var wins: Int = 0
    var losses: Int = 0
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var gameHistoryData: Data = Data()

    init() {}

    // MARK: - Nested Types

    struct GameRecord: Codable {
        let date: Date
        let humanWon: Bool
        let moves: Int
    }

    // MARK: - Computed

    var gameHistory: [GameRecord] {
        guard !gameHistoryData.isEmpty else { return [] }
        let decoder = JSONDecoder()
        return (try? decoder.decode([GameRecord].self, from: gameHistoryData)) ?? []
    }

    var winRate: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(wins) / Double(gamesPlayed)
    }

    // MARK: - Mutation

    func recordGame(humanWon: Bool, moves: Int) {
        gamesPlayed += 1
        if humanWon {
            wins += 1
            currentStreak = max(currentStreak + 1, 1)
            bestStreak = max(bestStreak, currentStreak)
        } else {
            losses += 1
            currentStreak = min(currentStreak - 1, -1)
        }

        let record = GameRecord(date: Date(), humanWon: humanWon, moves: moves)
        var history = gameHistory
        history.insert(record, at: 0)
        // Keep last 100 records
        if history.count > 100 { history = Array(history.prefix(100)) }

        let encoder = JSONEncoder()
        gameHistoryData = (try? encoder.encode(history)) ?? Data()
    }
}
