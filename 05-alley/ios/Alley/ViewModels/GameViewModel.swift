import SwiftUI
import SwiftData

@Observable final class GameViewModel {
    var playerNames: [String] = ["Player 1"]
    var balls: [[Int]] = [[]]       // balls[playerIndex]
    var currentPlayer: Int = 0
    var isSetup: Bool = true
    var gameId: UUID = UUID()
    var location: String = ""
    var isGameOver: Bool = false

    func startGame() {
        balls = Array(repeating: [], count: playerNames.count)
        currentPlayer = 0
        isSetup = false
        isGameOver = false
    }

    func recordBall(_ pins: Int, haptic: Bool = true, context: ModelContext) {
        guard currentPlayer < balls.count else { return }
        balls[currentPlayer].append(pins)

        if haptic {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }

        if BowlingEngine.isGameComplete(balls: balls[currentPlayer]) {
            if currentPlayer < playerNames.count - 1 {
                currentPlayer += 1
            } else {
                isGameOver = true
                saveGame(context: context)
            }
        }
    }

    func saveGame(context: ModelContext) {
        let allComplete = balls.allSatisfy { BowlingEngine.isGameComplete(balls: $0) }
        let encoded = (try? JSONEncoder().encode(balls)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        let game = BowlingGame(
            date: .now,
            playerNames: playerNames,
            ballsData: encoded,
            isComplete: allComplete,
            location: location
        )
        context.insert(game)
        try? context.save()
    }

    var currentPlayerName: String {
        currentPlayer < playerNames.count ? playerNames[currentPlayer] : "Player"
    }

    var maxPins: Int {
        guard currentPlayer < balls.count else { return 10 }
        return BowlingEngine.maxPinsForBall(balls: balls[currentPlayer])
    }

    func frameScores(for playerIdx: Int) -> [Int?] {
        guard playerIdx < balls.count else { return Array(repeating: nil, count: 10) }
        return BowlingEngine.frameScores(balls: balls[playerIdx])
    }

    func currentFrame(for playerIdx: Int) -> Int {
        guard playerIdx < balls.count else { return 0 }
        return BowlingEngine.currentFrame(balls: balls[playerIdx])
    }

    func currentBallInFrame(for playerIdx: Int) -> Int {
        guard playerIdx < balls.count else { return 0 }
        return BowlingEngine.currentBallInFrame(balls: balls[playerIdx])
    }

    func frameDisplayStrings(for playerIdx: Int) -> [(String, String)] {
        guard playerIdx < balls.count else { return [] }
        return BowlingEngine.frameDisplayStrings(balls: balls[playerIdx])
    }

    func undoLastBall() {
        if !isGameOver {
            if balls[currentPlayer].isEmpty && currentPlayer > 0 {
                currentPlayer -= 1
            }
            if !balls[currentPlayer].isEmpty {
                balls[currentPlayer].removeLast()
            }
        } else {
            isGameOver = false
            if !balls[currentPlayer].isEmpty {
                balls[currentPlayer].removeLast()
            }
        }
    }

    func resetGame() {
        playerNames = ["Player 1"]
        balls = [[]]
        currentPlayer = 0
        isSetup = true
        isGameOver = false
        gameId = UUID()
        location = ""
    }

    func addPlayer() {
        guard playerNames.count < 6 else { return }
        playerNames.append("Player \(playerNames.count + 1)")
    }

    func removePlayer(at index: Int) {
        guard playerNames.count > 1 else { return }
        playerNames.remove(at: index)
    }

    var canAddPlayer: Bool { playerNames.count < 6 }

    var currentScore: Int {
        guard currentPlayer < balls.count else { return 0 }
        return BowlingEngine.frameScores(balls: balls[currentPlayer]).compactMap { $0 }.last ?? 0
    }
}
