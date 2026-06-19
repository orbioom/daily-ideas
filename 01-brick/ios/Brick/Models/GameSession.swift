import Foundation
import SwiftData

@Model
final class BrickHighScore {
    var id: UUID
    var date: Date
    var level: Int
    var score: Int

    init(level: Int, score: Int) {
        self.id = UUID()
        self.date = Date()
        self.level = level
        self.score = score
    }
}

enum BrickGameState {
    case idle, playing, paused, dead, levelComplete
}

@Observable
final class BrickSession {
    var score: Int = 0
    var lives: Int = 3
    var level: Int = 1
    var state: BrickGameState = .idle
    var highScore: Int = 0
    var bricksRemaining: Int = 0

    func reset(level: Int, brickCount: Int) {
        self.level = level
        self.score = 0
        self.lives = 3
        self.bricksRemaining = brickCount
        self.state = .idle
    }

    func addScore(_ pts: Int) { score += pts }
    func loseLife() {
        lives -= 1
        if lives <= 0 {
            if score > highScore { highScore = score }
            state = .dead
        }
    }
    func brickDestroyed(points: Int) {
        addScore(points)
        bricksRemaining -= 1
        if bricksRemaining <= 0 {
            state = .levelComplete
        }
    }
}
