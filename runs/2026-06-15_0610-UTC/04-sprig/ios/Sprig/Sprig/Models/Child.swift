import Foundation
import SwiftData

/// A child being tracked. Owns growth measurements, milestone records, and vaccine records.
@Model
final class Child {
    @Attribute(.unique) var id: UUID
    var name: String
    var birthDate: Date
    var sexRaw: String
    var colorHex: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \GrowthMeasurement.child)
    var measurements: [GrowthMeasurement]

    @Relationship(deleteRule: .cascade, inverse: \MilestoneRecord.child)
    var milestoneRecords: [MilestoneRecord]

    @Relationship(deleteRule: .cascade, inverse: \VaccineRecord.child)
    var vaccineRecords: [VaccineRecord]

    init(id: UUID = UUID(),
         name: String,
         birthDate: Date,
         sex: Sex,
         colorHex: String = "3F9D6B",
         createdAt: Date = Date()) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.birthDate = birthDate
        self.sexRaw = sex.rawValue
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.measurements = []
        self.milestoneRecords = []
        self.vaccineRecords = []
    }

    var sex: Sex { Sex(rawValue: sexRaw) ?? .male }

    /// A friendly display name, never empty.
    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Baby" : trimmed
    }

    /// Whole age in months from birth to a reference date (leap-safe, Calendar-based).
    func ageMonths(asOf date: Date = Date()) -> Int {
        AgeMath.months(from: birthDate, to: date)
    }

    /// Fractional age in months (used by the percentile engine for interpolation).
    func ageMonthsExact(asOf date: Date = Date()) -> Double {
        AgeMath.exactMonths(from: birthDate, to: date)
    }

    /// Human-friendly age label, e.g. "1 yr 3 mo" or "5 mo" or "12 days".
    func ageDescription(asOf date: Date = Date()) -> String {
        AgeMath.description(from: birthDate, to: date)
    }

    /// Measurements sorted oldest → newest (safe copy).
    var sortedMeasurements: [GrowthMeasurement] {
        measurements.sorted { $0.date < $1.date }
    }

    var latestMeasurement: GrowthMeasurement? {
        sortedMeasurements.last
    }
}
