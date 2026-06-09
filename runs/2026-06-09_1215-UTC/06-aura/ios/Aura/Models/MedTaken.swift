import Foundation
import SwiftData

/// A single dose of medication taken during an attack. Belongs to one Attack
/// and is removed when that attack is deleted (cascade). `isAcute` is snapshotted
/// from the catalog at the time it was logged so overuse logic stays correct even
/// if the catalog entry later changes or is removed.
@Model
final class MedTaken {
    var name: String
    var doseMg: Double
    var minutesAfterOnset: Int
    var reliefRaw: String
    var isAcute: Bool
    var attack: Attack?

    init(name: String,
         doseMg: Double = 0,
         minutesAfterOnset: Int = 0,
         relief: Relief = .some,
         isAcute: Bool = true) {
        self.name = name
        self.doseMg = max(0, doseMg)
        self.minutesAfterOnset = max(0, minutesAfterOnset)
        self.reliefRaw = relief.rawValue
        self.isAcute = isAcute
    }

    var relief: Relief {
        get { Relief(rawValue: reliefRaw) ?? .none }
        set { reliefRaw = newValue.rawValue }
    }
}
