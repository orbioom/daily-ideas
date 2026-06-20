import Foundation
import SwiftData

@Model
final class PairResult {
    var id: UUID
    var date: Date
    var theme: String
    var gridSize: String
    var moves: Int
    var durationSeconds: Double
    var isDaily: Bool

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        theme: String,
        gridSize: String,
        moves: Int,
        durationSeconds: Double,
        isDaily: Bool = false
    ) {
        self.id = id
        self.date = date
        self.theme = theme
        self.gridSize = gridSize
        self.moves = moves
        self.durationSeconds = durationSeconds
        self.isDaily = isDaily
    }
}
