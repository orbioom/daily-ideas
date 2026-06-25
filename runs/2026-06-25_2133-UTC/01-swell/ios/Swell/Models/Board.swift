import Foundation
import SwiftData

enum BoardType: String, Codable, CaseIterable, Identifiable {
    case shortboard = "Shortboard"
    case longboard = "Longboard"
    case fish = "Fish"
    case funboard = "Funboard"
    case malibu = "Malibu / Mini Mal"
    case sup = "SUP"
    case bodyboard = "Bodyboard"
    case gun = "Gun"

    var id: String { rawValue }

    var sfSymbol: String { "surfboard" }
}

enum FinSetup: String, Codable, CaseIterable, Identifiable {
    case single = "Single"
    case twinFin = "Twin"
    case thruster = "Thruster"
    case quad = "Quad"
    case fiveFinBox = "2+1"
    case none = "None"

    var id: String { rawValue }
}

@Model
final class Board {
    var id: UUID = UUID()
    var name: String = ""
    var type: BoardType = BoardType.shortboard
    var lengthFt: Int = 6
    var lengthIn: Int = 2
    var volumeLiters: Double = 32.0
    var finSetup: FinSetup = FinSetup.thruster
    var notes: String = ""
    var isRetired: Bool = false
    var createdAt: Date = Date.now

    init(
        name: String,
        type: BoardType = .shortboard,
        lengthFt: Int = 6,
        lengthIn: Int = 2,
        volumeLiters: Double = 32.0,
        finSetup: FinSetup = .thruster,
        notes: String = "",
        isRetired: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.lengthFt = lengthFt
        self.lengthIn = lengthIn
        self.volumeLiters = volumeLiters
        self.finSetup = finSetup
        self.notes = notes
        self.isRetired = isRetired
        self.createdAt = .now
    }

    var displayLength: String { "\(lengthFt)'\(lengthIn)\"" }
}
