import Foundation
import SwiftData

/// One dated set of measurements for a child. Any field may be nil (you can record just weight,
/// just height, etc.). Values are stored in SI base units: kilograms and centimeters.
@Model
final class GrowthMeasurement {
    @Attribute(.unique) var id: UUID
    var date: Date
    var weightKg: Double?
    var heightCm: Double?
    var headCm: Double?
    var note: String?
    var child: Child?

    init(id: UUID = UUID(),
         date: Date = Date(),
         weightKg: Double? = nil,
         heightCm: Double? = nil,
         headCm: Double? = nil,
         note: String? = nil,
         child: Child? = nil) {
        self.id = id
        self.date = date
        self.weightKg = GrowthMeasurement.clean(weightKg, max: 60)
        self.heightCm = GrowthMeasurement.clean(heightCm, max: 200)
        self.headCm = GrowthMeasurement.clean(headCm, max: 70)
        self.note = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.child = child
    }

    /// Clamp to a sane positive range; reject non-finite or non-positive values.
    private static func clean(_ value: Double?, max upper: Double) -> Double? {
        guard let v = value, v.isFinite, v > 0 else { return nil }
        return Swift.min(v, upper)
    }

    /// The stored value for a given measure, in SI base units (kg or cm).
    func value(for measure: GrowthMeasure) -> Double? {
        switch measure {
        case .weight: return weightKg
        case .height: return heightCm
        case .head:   return headCm
        }
    }

    var hasAnyValue: Bool {
        weightKg != nil || heightCm != nil || headCm != nil
    }
}
