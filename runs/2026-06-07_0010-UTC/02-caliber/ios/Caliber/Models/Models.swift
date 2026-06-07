import Foundation
import SwiftData

/// A mechanical watch in the collection.
@Model
final class Watch {
    var name: String              // friendly name, e.g. "Daily Speedy"
    var brand: String
    var modelRef: String          // model / reference number
    var movement: String          // caliber, e.g. "ETA 2824-2"
    var purchaseDate: Date?
    var serviceIntervalYears: Int // recommended service interval
    var lastServiced: Date?
    var powerReserveHours: Int
    var isFavorite: Bool
    var accentHex: UInt32         // a per-watch tint for the strap dot
    var notes: String
    @Relationship(deleteRule: .cascade, inverse: \WatchMeasurement.watch)
    var measurements: [WatchMeasurement]

    init(name: String = "", brand: String = "", modelRef: String = "",
         movement: String = "", purchaseDate: Date? = nil,
         serviceIntervalYears: Int = 5, lastServiced: Date? = nil,
         powerReserveHours: Int = 42, isFavorite: Bool = false,
         accentHex: UInt32 = 0x4FB98C, notes: String = "") {
        self.name = name
        self.brand = brand
        self.modelRef = modelRef
        self.movement = movement
        self.purchaseDate = purchaseDate
        self.serviceIntervalYears = serviceIntervalYears
        self.lastServiced = lastServiced
        self.powerReserveHours = powerReserveHours
        self.isFavorite = isFavorite
        self.accentHex = accentHex
        self.notes = notes
        self.measurements = []
    }

    var displayName: String { name.isEmpty ? (brand.isEmpty ? "Untitled watch" : brand) : name }
    var sortedMeasurements: [WatchMeasurement] {
        measurements.sorted { $0.timestamp > $1.timestamp }
    }

    var dailyRate: Double? { RateEngine.dailyRate(measurements) }
    var grade: AccuracyGrade { AccuracyGrade.from(rate: dailyRate) }

    /// Next service due date, derived from last service + interval.
    var nextServiceDue: Date? {
        guard let last = lastServiced else { return nil }
        return Calendar.current.date(byAdding: .year, value: serviceIntervalYears, to: last)
    }

    /// Days until next service (negative = overdue), or nil if never serviced.
    var daysUntilService: Int? {
        guard let due = nextServiceDue else { return nil }
        return Calendar.current.dateComponents([.day], from: .now, to: due).day
    }
}

/// A single timing reading for a watch.
@Model
final class WatchMeasurement {
    var timestamp: Date           // when the reading was taken
    var offsetSeconds: Double     // watch minus reference; + = fast
    var position: WatchPosition
    var note: String
    var watch: Watch?

    init(timestamp: Date = .now, offsetSeconds: Double = 0,
         position: WatchPosition = .onWrist, note: String = "") {
        self.timestamp = timestamp
        self.offsetSeconds = offsetSeconds
        self.position = position
        self.note = note
    }
}
