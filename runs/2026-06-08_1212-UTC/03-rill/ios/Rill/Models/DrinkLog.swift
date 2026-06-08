import Foundation
import SwiftData

/// A single logged drink. Drink attributes are snapshotted so that editing or
/// deleting a DrinkType never rewrites your history.
@Model
final class DrinkLog {
    var id: UUID
    var date: Date
    var volumeML: Double
    var hydrationFactor: Double
    var caffeineMg: Double
    var drinkName: String
    var drinkSymbol: String
    var drinkColorHex: UInt32

    init(
        id: UUID = UUID(),
        date: Date = .now,
        volumeML: Double,
        hydrationFactor: Double,
        caffeineMg: Double = 0,
        drinkName: String,
        drinkSymbol: String,
        drinkColorHex: UInt32
    ) {
        self.id = id
        self.date = date
        self.volumeML = max(0, volumeML)
        self.hydrationFactor = min(1.2, max(0, hydrationFactor))
        self.caffeineMg = max(0, caffeineMg)
        self.drinkName = drinkName
        self.drinkSymbol = drinkSymbol
        self.drinkColorHex = drinkColorHex
    }

    /// Effective hydration this drink contributes (ml of "pure water equivalent").
    var effectiveML: Double { volumeML * hydrationFactor }

    convenience init(from type: DrinkType, volumeML: Double, date: Date = .now) {
        self.init(
            date: date,
            volumeML: volumeML,
            hydrationFactor: type.hydrationFactor,
            caffeineMg: volumeML * type.caffeineMgPerML,
            drinkName: type.name,
            drinkSymbol: type.symbol,
            drinkColorHex: type.colorHex
        )
    }
}
