import Foundation
import SwiftData

/// A completed game, persisted for History + Stats. Player names / scores are stored as
/// JSON strings so the model stays a flat, query-friendly SwiftData record.
@Model
final class GameRecord {
    var date: Date
    /// Raw value of `GameMode`.
    var modeRaw: String
    /// JSON-encoded `[String]` of player names in seating order.
    var playerNamesJSON: String
    /// JSON-encoded `[Int]` of final grand totals, parallel to player names.
    var finalScoresJSON: String
    /// JSON-encoded `[String: Int]` of the human player's per-category scores (for category stats).
    var myCategoryScoresJSON: String
    var winnerName: String
    /// The human/"me" player's grand total in this game.
    var myScore: Int
    /// Count of Yahtzees the human player rolled this game.
    var myYahtzees: Int
    /// True if the human player won.
    var didWin: Bool

    init(date: Date, mode: GameMode, playerNames: [String], finalScores: [Int],
         myCategoryScores: [ScoreCategory: Int], winnerName: String, myScore: Int,
         myYahtzees: Int, didWin: Bool) {
        self.date = date
        self.modeRaw = mode.rawValue
        self.playerNamesJSON = JSONCoder.encodeStrings(playerNames)
        self.finalScoresJSON = JSONCoder.encodeInts(finalScores)
        self.myCategoryScoresJSON = JSONCoder.encodeCategoryScores(myCategoryScores)
        self.winnerName = winnerName
        self.myScore = myScore
        self.myYahtzees = myYahtzees
        self.didWin = didWin
    }

    var mode: GameMode { GameMode(rawValue: modeRaw) ?? .solo }
    var playerNames: [String] { JSONCoder.decodeStrings(playerNamesJSON) }
    var finalScores: [Int] { JSONCoder.decodeInts(finalScoresJSON) }
    var myCategoryScores: [ScoreCategory: Int] { JSONCoder.decodeCategoryScores(myCategoryScoresJSON) }

    /// Tuples of (name, score) zipped together, longest-safe.
    var standings: [(name: String, score: Int)] {
        let names = playerNames
        let scores = finalScores
        let n = min(names.count, scores.count)
        return (0..<n).map { (names[$0], scores[$0]) }
    }
}

/// Tiny JSON helpers so models never `try!`.
enum JSONCoder {
    private static func jsonString(_ data: Data?, fallback: String) -> String {
        guard let data, let str = String(data: data, encoding: .utf8) else { return fallback }
        return str
    }

    static func encodeStrings(_ v: [String]) -> String {
        jsonString(try? JSONEncoder().encode(v), fallback: "[]")
    }
    static func decodeStrings(_ s: String) -> [String] {
        guard let data = s.data(using: .utf8),
              let v = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return v
    }
    static func encodeInts(_ v: [Int]) -> String {
        jsonString(try? JSONEncoder().encode(v), fallback: "[]")
    }
    static func decodeInts(_ s: String) -> [Int] {
        guard let data = s.data(using: .utf8),
              let v = try? JSONDecoder().decode([Int].self, from: data) else { return [] }
        return v
    }
    static func encodeCategoryScores(_ v: [ScoreCategory: Int]) -> String {
        let raw = Dictionary(uniqueKeysWithValues: v.map { ($0.key.rawValue, $0.value) })
        return jsonString(try? JSONEncoder().encode(raw), fallback: "{}")
    }
    static func decodeCategoryScores(_ s: String) -> [ScoreCategory: Int] {
        guard let data = s.data(using: .utf8),
              let raw = try? JSONDecoder().decode([String: Int].self, from: data) else { return [:] }
        var out: [ScoreCategory: Int] = [:]
        for (k, val) in raw {
            if let cat = ScoreCategory(rawValue: k) { out[cat] = val }
        }
        return out
    }
}
