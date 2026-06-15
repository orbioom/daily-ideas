import Foundation
import SwiftData

/// A single poker session. Money is stored as `Decimal`.
/// For tournaments, `buyIn` is total invested (entry + rebuys) and `cashOut` is the prize won.
@Model
final class Session {
    @Attribute(.unique) var id: UUID
    var date: Date
    var formatRaw: String
    var gameTypeRaw: String
    var location: String
    var stakes: String
    var durationMinutes: Int
    var buyIn: Decimal
    var cashOut: Decimal
    var tournamentEntries: Int?
    var tournamentPlace: Int?
    var notes: String
    var tag: String

    init(id: UUID = UUID(),
         date: Date = .now,
         format: SessionFormat = .cash,
         gameType: GameType = .nlhe,
         location: String = "",
         stakes: String = "",
         durationMinutes: Int = 0,
         buyIn: Decimal = 0,
         cashOut: Decimal = 0,
         tournamentEntries: Int? = nil,
         tournamentPlace: Int? = nil,
         notes: String = "",
         tag: String = "") {
        self.id = id
        self.date = date
        self.formatRaw = format.rawValue
        self.gameTypeRaw = gameType.rawValue
        self.location = location
        self.stakes = stakes
        self.durationMinutes = durationMinutes
        self.buyIn = buyIn
        self.cashOut = cashOut
        self.tournamentEntries = tournamentEntries
        self.tournamentPlace = tournamentPlace
        self.notes = notes
        self.tag = tag
    }

    var format: SessionFormat {
        get { SessionFormat(rawValue: formatRaw) ?? .cash }
        set { formatRaw = newValue.rawValue }
    }

    var gameType: GameType {
        get { GameType(rawValue: gameTypeRaw) ?? .nlhe }
        set { gameTypeRaw = newValue.rawValue }
    }

    /// Net result for the session.
    var profit: Decimal { cashOut - buyIn }

    /// Session length in hours (guarded — minutes are non-negative by construction in the editor).
    var hours: Double { Double(max(0, durationMinutes)) / 60.0 }

    /// Whether the session was a winner.
    var isWin: Bool { profit > 0 }
}
