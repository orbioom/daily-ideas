import Foundation
import SwiftData

/// A weekly weigh-in. Drives the adaptive-TDEE recalibration and trend charts.
@Model
final class CheckIn {
    @Attribute(.unique) var id: UUID
    var date: Date
    var weightKg: Double
    var avgDailyIntakeKcal: Double?
    var note: String

    init(id: UUID = UUID(),
         date: Date,
         weightKg: Double,
         avgDailyIntakeKcal: Double? = nil,
         note: String = "") {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.avgDailyIntakeKcal = avgDailyIntakeKcal
        self.note = note
    }

    /// Convert to the engine's lightweight sample type.
    var sample: WeighSample {
        WeighSample(id: id, date: date, weightKg: weightKg, avgIntakeKcal: avgDailyIntakeKcal)
    }
}
