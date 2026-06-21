import SwiftData
import Foundation

@Model final class BowlingGame {
    var id: UUID
    var date: Date
    var playerNames: [String]
    var ballsData: String          // JSON: [[Int]] — balls[playerIndex][ballIndex]
    var isComplete: Bool
    var location: String

    init(id: UUID = UUID(), date: Date = .now, playerNames: [String], ballsData: String = "[]", isComplete: Bool = false, location: String = "") {
        self.id = id
        self.date = date
        self.playerNames = playerNames
        self.ballsData = ballsData
        self.isComplete = isComplete
        self.location = location
    }

    var decodedBalls: [[Int]] {
        (try? JSONDecoder().decode([[Int]].self, from: Data(ballsData.utf8))) ?? []
    }

    func finalScores() -> [Int?] {
        let allBalls = decodedBalls
        return allBalls.map { balls in
            let scores = BowlingEngine.frameScores(balls: balls)
            return scores.compactMap { $0 }.last
        }
    }

    func totalPins() -> Int {
        decodedBalls.flatMap { $0 }.reduce(0, +)
    }

    func strikeCount() -> Int {
        var count = 0
        for playerBalls in decodedBalls {
            var idx = 0
            for frame in 0..<10 {
                guard idx < playerBalls.count else { break }
                if frame < 9 {
                    if playerBalls[idx] == 10 {
                        count += 1
                        idx += 1
                    } else {
                        idx += 2
                    }
                } else {
                    if playerBalls[idx] == 10 { count += 1 }
                    if playerBalls.count > idx + 1 && playerBalls[idx + 1] == 10 { count += 1 }
                }
            }
        }
        return count
    }

    func totalBalls() -> Int {
        decodedBalls.flatMap { $0 }.count
    }
}

@Model final class AlleySettings {
    var showRunningTotal: Bool
    var hapticEnabled: Bool
    var defaultPlayerCount: Int
    var showPinDiagram: Bool
    var soundEnabled: Bool
    var hasCompletedOnboarding: Bool
    var isPro: Bool

    init() {
        showRunningTotal = true
        hapticEnabled = true
        defaultPlayerCount = 1
        showPinDiagram = true
        soundEnabled = false
        hasCompletedOnboarding = false
        isPro = false
    }
}
