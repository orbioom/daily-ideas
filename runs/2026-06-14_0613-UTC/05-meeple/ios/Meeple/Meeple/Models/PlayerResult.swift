import Foundation
import SwiftData

@Model
final class PlayerResult {
    @Attribute(.unique) var id: UUID
    /// Snapshot of the player's name at log time so deleting a Player never corrupts history.
    var playerName: String
    var score: Int?            // optional — not every game is scored
    var isWinner: Bool
    var colorHue: Int          // snapshot for stable display chips

    var play: Play?

    init(
        id: UUID = UUID(),
        playerName: String,
        score: Int? = nil,
        isWinner: Bool = false,
        colorHue: Int = 0,
        play: Play? = nil
    ) {
        self.id = id
        self.playerName = playerName
        self.score = score
        self.isWinner = isWinner
        self.colorHue = colorHue
        self.play = play
    }
}
