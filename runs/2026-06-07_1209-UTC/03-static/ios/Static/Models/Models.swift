import Foundation
import SwiftData

/// The two classic apnea training tables.
enum TableType: String, CaseIterable, Identifiable {
    case co2 = "CO₂"
    case o2 = "O₂"
    var id: String { rawValue }
    var subtitle: String {
        switch self {
        case .co2: return "Fixed holds, shrinking rests — builds tolerance to carbon dioxide."
        case .o2: return "Fixed rests, growing holds — trains efficiency at low oxygen."
        }
    }
    var symbol: String { self == .co2 ? "wind" : "lungs" }
}

/// A saved, parametric training table. The per-round schedule is derived from
/// these parameters by `TableEngine`, so a table is small and reproducible.
@Model
final class ApneaTable {
    var id: UUID = UUID()
    var name: String = ""
    var typeRaw: String = TableType.co2.rawValue
    var maxHoldSeconds: Int = 180
    var rounds: Int = 8
    var createdAt: Date = Date()

    init(name: String, type: TableType, maxHoldSeconds: Int, rounds: Int = 8) {
        self.id = UUID()
        self.name = name
        self.typeRaw = type.rawValue
        self.maxHoldSeconds = max(30, maxHoldSeconds)
        self.rounds = max(2, min(12, rounds))
        self.createdAt = Date()
    }

    var type: TableType {
        get { TableType(rawValue: typeRaw) ?? .co2 }
        set { typeRaw = newValue.rawValue }
    }
    var schedule: [ApneaRound] { TableEngine.schedule(type: type, maxHold: maxHoldSeconds, rounds: rounds) }
    var totalSeconds: Int { TableEngine.totalSeconds(schedule) }
    var longestHold: Int { schedule.map { $0.holdSeconds }.max() ?? 0 }
}

/// A completed (or abandoned) training session, for the log and progress trend.
@Model
final class ApneaSession {
    var id: UUID = UUID()
    var date: Date = Date()
    var tableName: String = ""
    var typeRaw: String = TableType.co2.rawValue
    var roundsPlanned: Int = 8
    var roundsCompleted: Int = 0
    var longestHoldSeconds: Int = 0
    var notes: String = ""

    init(date: Date = Date(), tableName: String, type: TableType,
         roundsPlanned: Int, roundsCompleted: Int, longestHoldSeconds: Int, notes: String = "") {
        self.id = UUID()
        self.date = date
        self.tableName = tableName
        self.typeRaw = type.rawValue
        self.roundsPlanned = roundsPlanned
        self.roundsCompleted = roundsCompleted
        self.longestHoldSeconds = longestHoldSeconds
        self.notes = notes
    }

    var type: TableType { TableType(rawValue: typeRaw) ?? .co2 }
    var completed: Bool { roundsCompleted >= roundsPlanned }
}
