import Foundation
import SwiftData

@Model final class HoopGame {
    var date: Date
    var teamAName: String
    var teamBName: String
    var quarters: Int
    var quarterMinutes: Int
    var overtimePeriods: Int
    var isComplete: Bool

    // Quarter-by-quarter scores stored as JSON
    var quarterScoresAData: Data
    var quarterScoresBData: Data

    // Final scores
    var finalScoreA: Int
    var finalScoreB: Int

    @Relationship(deleteRule: .cascade) var players: [HoopPlayer] = []

    init(
        teamAName: String,
        teamBName: String,
        quarters: Int = 4,
        quarterMinutes: Int = 10
    ) {
        self.date = Date()
        self.teamAName = teamAName
        self.teamBName = teamBName
        self.quarters = quarters
        self.quarterMinutes = quarterMinutes
        self.overtimePeriods = 0
        self.isComplete = false
        self.quarterScoresAData = (try? JSONEncoder().encode([Int](repeating: 0, count: quarters))) ?? Data()
        self.quarterScoresBData = (try? JSONEncoder().encode([Int](repeating: 0, count: quarters))) ?? Data()
        self.finalScoreA = 0
        self.finalScoreB = 0
    }

    func decodeQuarterScoresA() -> [Int] {
        (try? JSONDecoder().decode([Int].self, from: quarterScoresAData)) ?? []
    }

    func decodeQuarterScoresB() -> [Int] {
        (try? JSONDecoder().decode([Int].self, from: quarterScoresBData)) ?? []
    }

    func encodeQuarterScores(a: [Int], b: [Int]) {
        quarterScoresAData = (try? JSONEncoder().encode(a)) ?? Data()
        quarterScoresBData = (try? JSONEncoder().encode(b)) ?? Data()
        finalScoreA = a.reduce(0, +)
        finalScoreB = b.reduce(0, +)
    }

    var winner: String? {
        guard isComplete else { return nil }
        if finalScoreA > finalScoreB { return teamAName }
        if finalScoreB > finalScoreA { return teamBName }
        return "Tie"
    }

    var playersA: [HoopPlayer] {
        players.filter { $0.team == "A" }.sorted { $0.totalPoints > $1.totalPoints }
    }

    var playersB: [HoopPlayer] {
        players.filter { $0.team == "B" }.sorted { $0.totalPoints > $1.totalPoints }
    }
}

@Model final class HoopPlayer {
    var name: String
    var number: String
    var team: String
    var points2: Int
    var points3: Int
    var freeThrowsMade: Int
    var freeThrowsAttempted: Int
    var fouls: Int
    var game: HoopGame?

    var totalPoints: Int { points2 * 2 + points3 * 3 + freeThrowsMade }

    init(name: String, number: String, team: String) {
        self.name = name
        self.number = number
        self.team = team
        self.points2 = 0
        self.points3 = 0
        self.freeThrowsMade = 0
        self.freeThrowsAttempted = 0
        self.fouls = 0
    }
}
