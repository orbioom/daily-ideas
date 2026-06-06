import Foundation
import SwiftData

/// A single feeding of a `Starter`, recorded as a ratio of starter : flour : water
/// (e.g. 1:2:2), the flour used, and a note.
@Model
final class Feeding {
    var id: UUID
    var date: Date
    /// Ratio parts. Each guarded to be > 0 when displayed.
    var starterParts: Double
    var flourParts: Double
    var waterParts: Double
    var flourType: String
    var notes: String

    /// Owning starter. Optional so SwiftData can manage the inverse relationship.
    var starter: Starter?

    init(id: UUID = UUID(),
         date: Date = .now,
         starterParts: Double = 1,
         flourParts: Double = 2,
         waterParts: Double = 2,
         flourType: String = "Bread flour",
         notes: String = "") {
        self.id = id
        self.date = date
        self.starterParts = starterParts
        self.flourParts = flourParts
        self.waterParts = waterParts
        self.flourType = flourType
        self.notes = notes
    }

    /// A clean "1:2:2"-style ratio string (trailing zeros trimmed).
    var ratioString: String {
        func fmt(_ v: Double) -> String {
            if v == v.rounded() { return String(Int(v)) }
            return String(format: "%.1f", v)
        }
        return "\(fmt(starterParts)):\(fmt(flourParts)):\(fmt(waterParts))"
    }

    /// Hydration implied by this feeding's water/flour ratio, as a percentage.
    var impliedHydration: Double {
        guard flourParts > 0 else { return 0 }
        return waterParts / flourParts * 100
    }
}
