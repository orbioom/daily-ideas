import Foundation
import SwiftData

/// A single weigh-in. Weight is always stored in kilograms (canonical) and
/// converted for display, so changing units never rewrites your data.
@Model
final class WeightEntry {
    var id: UUID
    var date: Date
    var kilograms: Double
    var note: String

    init(id: UUID = UUID(), date: Date = .now, kilograms: Double, note: String = "") {
        self.id = id
        self.date = date
        self.kilograms = kilograms
        self.note = note
    }
}
