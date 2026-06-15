import Foundation
import SwiftData

/// A completed (won or lost/abandoned-as-recorded) game, for stats.
@Model
final class GameRecord {
    /// Raw value of `LayoutKind`.
    var layoutRaw: String
    var won: Bool
    var durationSec: Int
    var moves: Int
    var date: Date

    init(layout: LayoutKind, won: Bool, durationSec: Int, moves: Int, date: Date = .now) {
        self.layoutRaw = layout.rawValue
        self.won = won
        self.durationSec = max(0, durationSec)
        self.moves = max(0, moves)
        self.date = date
    }

    var layout: LayoutKind { LayoutKind(rawValue: layoutRaw) ?? .turtle }
}

/// The single in-progress game, persisted so it survives relaunch.
@Model
final class SavedGame {
    /// Raw value of `LayoutKind`.
    var layoutRaw: String
    /// Codable-encoded `SavedGameState`.
    var stateData: Data
    var savedAt: Date
    /// True for the daily challenge board.
    var isDaily: Bool

    init(layout: LayoutKind, stateData: Data, savedAt: Date = .now, isDaily: Bool = false) {
        self.layoutRaw = layout.rawValue
        self.stateData = stateData
        self.savedAt = savedAt
        self.isDaily = isDaily
    }

    var layout: LayoutKind { LayoutKind(rawValue: layoutRaw) ?? .turtle }
}

/// One day's Daily Challenge result.
@Model
final class DailyResult {
    /// "yyyy-MM-dd" in the user's calendar.
    var dateKey: String
    var layoutRaw: String
    var won: Bool
    var durationSec: Int
    var recordedAt: Date

    init(dateKey: String, layout: LayoutKind, won: Bool, durationSec: Int, recordedAt: Date = .now) {
        self.dateKey = dateKey
        self.layoutRaw = layout.rawValue
        self.won = won
        self.durationSec = max(0, durationSec)
        self.recordedAt = recordedAt
    }

    var layout: LayoutKind { LayoutKind(rawValue: layoutRaw) ?? .turtle }
}
