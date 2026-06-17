import Foundation
import SwiftData

@Model
final class MeasurementEntry {
    @Attribute(.unique) var id: UUID
    var siteKey: String
    /// Stored canonically: kg for mass, cm for length, percent for percent.
    var valueCanonical: Double
    var date: Date

    init(id: UUID = UUID(), siteKey: String, valueCanonical: Double, date: Date) {
        self.id = id
        self.siteKey = siteKey
        self.valueCanonical = valueCanonical
        self.date = date
    }
}
