import Foundation
import SwiftData

/// A logged match between two sides. Players appear on `mySide` / `oppSide`
/// (one each for singles, two each for doubles). Games are stored as cascading
/// `GameScore` children. Relationships are deliberately simple to-many links
/// with a nullify delete rule so removing a player never deletes their matches.
@Model
final class Match {
    var date: Date
    var sportRaw: String
    var formatRaw: String
    var pointsToWin: Int
    var winByTwo: Bool
    var location: String
    var note: String
    var isComplete: Bool
    var myGamesWon: Int
    var oppGamesWon: Int

    @Relationship(deleteRule: .nullify) var mySide: [Player]
    @Relationship(deleteRule: .nullify) var oppSide: [Player]
    @Relationship(deleteRule: .cascade) var games: [GameScore]

    init(date: Date = .now,
         sport: Sport = .pickleball,
         format: MatchFormat = .singles,
         pointsToWin: Int = 11,
         winByTwo: Bool = true,
         location: String = "",
         note: String = "",
         isComplete: Bool = false,
         myGamesWon: Int = 0,
         oppGamesWon: Int = 0,
         mySide: [Player] = [],
         oppSide: [Player] = [],
         games: [GameScore] = []) {
        self.date = date
        self.sportRaw = sport.rawValue
        self.formatRaw = format.rawValue
        self.pointsToWin = pointsToWin
        self.winByTwo = winByTwo
        self.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        self.note = note
        self.isComplete = isComplete
        self.myGamesWon = myGamesWon
        self.oppGamesWon = oppGamesWon
        self.mySide = mySide
        self.oppSide = oppSide
        self.games = games
    }

    // MARK: - Derived values

    var sport: Sport { Sport(rawValue: sportRaw) ?? .pickleball }
    var format: MatchFormat { MatchFormat(rawValue: formatRaw) ?? .singles }

    /// True when my side won more games than the opponent.
    var didWin: Bool { myGamesWon > oppGamesWon }

    /// Games sorted by their play order.
    var orderedGames: [GameScore] { games.sorted { $0.order < $1.order } }

    /// "2–1" style games-won line from my perspective.
    var gamesLine: String { "\(myGamesWon)–\(oppGamesWon)" }

    /// A compact per-game score summary, e.g. "11–7, 9–11, 11–8".
    var gamesDetail: String {
        orderedGames.map(\.line).joined(separator: ", ")
    }

    /// Display name for the opponent side (handles empty/doubles).
    var oppNames: String {
        let names = oppSide.map(\.name).filter { !$0.isEmpty }
        return names.isEmpty ? "Unknown" : names.joined(separator: " & ")
    }

    /// Display name for my side.
    var myNames: String {
        let names = mySide.map(\.name).filter { !$0.isEmpty }
        return names.isEmpty ? "You" : names.joined(separator: " & ")
    }

    /// Total points scored across all games, by side.
    var myPoints: Int { games.reduce(0) { $0 + $1.myScore } }
    var oppPoints: Int { games.reduce(0) { $0 + $1.oppScore } }
}
