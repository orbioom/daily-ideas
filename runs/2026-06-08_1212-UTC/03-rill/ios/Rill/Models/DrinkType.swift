import Foundation
import SwiftData

/// A kind of drink the user can quick-add. Ships with a sensible catalog;
/// users can add their own. `hydrationFactor` is the net-hydration coefficient
/// (water = 1.0, coffee ≈ 0.85, beer ≈ 0.5) so alcohol and caffeine count
/// honestly rather than as if they were pure water.
@Model
final class DrinkType {
    var id: UUID
    var name: String
    var symbol: String
    var colorHex: UInt32
    var defaultVolumeML: Double
    var hydrationFactor: Double
    var caffeineMgPerML: Double     // 0 for non-caffeinated
    var isCustom: Bool
    var order: Int

    init(
        id: UUID = UUID(),
        name: String,
        symbol: String,
        colorHex: UInt32,
        defaultVolumeML: Double,
        hydrationFactor: Double = 1.0,
        caffeineMgPerML: Double = 0,
        isCustom: Bool = false,
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.defaultVolumeML = max(1, defaultVolumeML)
        self.hydrationFactor = min(1.2, max(0, hydrationFactor))
        self.caffeineMgPerML = max(0, caffeineMgPerML)
        self.isCustom = isCustom
        self.order = order
    }

    static var catalog: [DrinkType] {
        [
            DrinkType(name: "Water", symbol: "drop.fill", colorHex: 0x3E7EA6, defaultVolumeML: 250, hydrationFactor: 1.0, order: 0),
            DrinkType(name: "Large Water", symbol: "drop.fill", colorHex: 0x3E7EA6, defaultVolumeML: 500, hydrationFactor: 1.0, order: 1),
            DrinkType(name: "Coffee", symbol: "cup.and.saucer.fill", colorHex: 0x8A5A3E, defaultVolumeML: 240, hydrationFactor: 0.85, caffeineMgPerML: 0.4, order: 2),
            DrinkType(name: "Tea", symbol: "cup.and.saucer.fill", colorHex: 0x6E8A4E, defaultVolumeML: 240, hydrationFactor: 0.9, caffeineMgPerML: 0.2, order: 3),
            DrinkType(name: "Juice", symbol: "takeoutbag.and.cup.and.straw.fill", colorHex: 0xB0814E, defaultVolumeML: 200, hydrationFactor: 0.9, order: 4),
            DrinkType(name: "Sparkling", symbol: "bubbles.and.sparkles", colorHex: 0x4E9EA6, defaultVolumeML: 330, hydrationFactor: 1.0, order: 5),
            DrinkType(name: "Sports Drink", symbol: "bolt.fill", colorHex: 0x3E9E78, defaultVolumeML: 500, hydrationFactor: 1.1, order: 6),
            DrinkType(name: "Soda", symbol: "cup.and.saucer.fill", colorHex: 0x9E5E7E, defaultVolumeML: 330, hydrationFactor: 0.85, caffeineMgPerML: 0.1, order: 7),
            DrinkType(name: "Beer", symbol: "wineglass.fill", colorHex: 0xC0953E, defaultVolumeML: 330, hydrationFactor: 0.5, order: 8),
            DrinkType(name: "Milk", symbol: "drop.fill", colorHex: 0xCFD3DD, defaultVolumeML: 200, hydrationFactor: 0.9, order: 9),
        ]
    }
}
