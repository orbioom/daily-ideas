import Foundation
import SwiftData

/// A record that an item was worn on a date. Outfits log a wear for each of
/// their items, so cost-per-wear stays accurate however you log.
@Model
final class WearLog {
    var id: UUID
    var date: Date
    var item: ClothingItem?

    init(id: UUID = UUID(), date: Date = .now, item: ClothingItem? = nil) {
        self.id = id
        self.date = date
        self.item = item
    }
}

/// A planned outfit on a calendar day.
@Model
final class OutfitPlan {
    var id: UUID
    var date: Date          // start of day
    var outfit: Outfit?
    var worn: Bool

    init(id: UUID = UUID(), date: Date, outfit: Outfit? = nil, worn: Bool = false) {
        self.id = id
        self.date = date
        self.outfit = outfit
        self.worn = worn
    }
}
