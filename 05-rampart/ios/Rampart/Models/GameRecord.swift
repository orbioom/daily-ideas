import Foundation
import SwiftData

@Model
final class GameRecord {
    var id: UUID
    var mapID: Int
    var mapName: String
    var wave: Int
    var score: Int
    var won: Bool
    var date: Date

    init(mapID: Int, mapName: String, wave: Int, score: Int, won: Bool) {
        self.id = UUID()
        self.mapID = mapID
        self.mapName = mapName
        self.wave = wave
        self.score = score
        self.won = won
        self.date = Date()
    }
}
