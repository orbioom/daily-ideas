import Foundation
import SwiftData

@Model final class HoopGame {
    var date: Date
    var teamAName: String
    var teamBName: String
    var quarters: Int
    var quarterMinutes: Int
    var finalScoreA: Int
    var finalScoreB: Int
    var quarterScoresAData: Data   // JSON [Int]
    var quarterScoresBData: Data   // JSON [Int]
    @Relationship(deleteRule: .cascade) var players: [HoopPlayer] = []
    
    init(teamAName: String, teamBName: String, quarters: Int = 4, quarterMinutes: Int = 10) {
        self.teamAName = teamAName; self.teamBName = teamBName
        self.quarters = quarters; self.quarterMinutes = quarterMinutes
        self.finalScoreA = 0; self.finalScoreB = 0
        self.date = .now
        self.quarterScoresAData = (try? JSONEncoder().encode([Int]())) ?? Data()
        self.quarterScoresBData = (try? JSONEncoder().encode([Int]())) ?? Data()
    }
    
    func decodeScoresA() -> [Int] { (try? JSONDecoder().decode([Int].self, from: quarterScoresAData)) ?? [] }
    func decodeScoresB() -> [Int] { (try? JSONDecoder().decode([Int].self, from: quarterScoresBData)) ?? [] }
    func encodeScores(a: [Int], b: [Int]) {
        quarterScoresAData = (try? JSONEncoder().encode(a)) ?? Data()
        quarterScoresBData = (try? JSONEncoder().encode(b)) ?? Data()
    }
    
    var winnerName: String {
        if finalScoreA > finalScoreB { return teamAName }
        if finalScoreB > finalScoreA { return teamBName }
        return "Tie"
    }
}

@Model final class HoopPlayer {
    var name: String
    var number: String
    var team: String   // "A" or "B"
    var points2: Int
    var points3: Int
    var freeThrowsMade: Int
    var freeThrowsAttempted: Int
    var fouls: Int
    var game: HoopGame?
    
    init(name: String, number: String = "", team: String = "A") {
        self.name = name; self.number = number; self.team = team
        self.points2 = 0; self.points3 = 0
        self.freeThrowsMade = 0; self.freeThrowsAttempted = 0; self.fouls = 0
    }
    
    var totalPoints: Int { points2 * 2 + points3 * 3 + freeThrowsMade }
}
