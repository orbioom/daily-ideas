import Foundation
import SwiftData

@Model
final class Play {
    @Attribute(.unique) var id: UUID
    var date: Date
    var durationMin: Int
    var location: String
    var notes: String

    @Relationship(deleteRule: .cascade, inverse: \PlayerResult.play)
    var results: [PlayerResult]

    var game: BoardGame?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        durationMin: Int = 0,
        location: String = "",
        notes: String = "",
        game: BoardGame? = nil
    ) {
        self.id = id
        self.date = date
        self.durationMin = max(0, durationMin)
        self.location = location
        self.notes = notes
        self.results = []
        self.game = game
    }

    /// Winners by name snapshot (may be multiple in a tie).
    var winnerNames: [String] {
        results.filter { $0.isWinner }.map { $0.playerName }
    }

    var hasScores: Bool {
        results.contains { $0.score != nil }
    }
}
