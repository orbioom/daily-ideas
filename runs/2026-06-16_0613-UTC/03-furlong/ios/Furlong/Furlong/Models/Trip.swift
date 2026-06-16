import Foundation
import SwiftData

@Model
final class Trip {
    var date: Date
    var purposeRaw: String
    /// Canonical one-way distance in MILES (before round-trip doubling).
    var miles: Double
    /// Optional odometer readings; when both present `miles` is derived from them.
    var startOdometer: Double?
    var endOdometer: Double?
    var fromLabel: String
    var toLabel: String
    var roundTrip: Bool
    var notes: String
    var createdAt: Date

    var vehicle: Vehicle?

    init(date: Date = .now,
         purpose: TripPurpose = .business,
         miles: Double = 0,
         startOdometer: Double? = nil,
         endOdometer: Double? = nil,
         fromLabel: String = "",
         toLabel: String = "",
         roundTrip: Bool = false,
         notes: String = "",
         vehicle: Vehicle? = nil,
         createdAt: Date = .now) {
        self.date = date
        self.purposeRaw = purpose.rawValue
        self.miles = miles
        self.startOdometer = startOdometer
        self.endOdometer = endOdometer
        self.fromLabel = fromLabel
        self.toLabel = toLabel
        self.roundTrip = roundTrip
        self.notes = notes
        self.vehicle = vehicle
        self.createdAt = createdAt
    }

    var purpose: TripPurpose {
        get { TripPurpose(rawValue: purposeRaw) ?? .business }
        set { purposeRaw = newValue.rawValue }
    }

    /// Effective deductible/counted distance in canonical miles, applying the
    /// round-trip doubling. Always non-negative.
    var effectiveMiles: Double {
        let base = max(0, miles)
        return roundTrip ? base * 2 : base
    }

    var routeLabel: String {
        let from = fromLabel.trimmingCharacters(in: .whitespaces)
        let to = toLabel.trimmingCharacters(in: .whitespaces)
        if from.isEmpty && to.isEmpty { return "Trip" }
        if to.isEmpty { return from }
        if from.isEmpty { return to }
        return "\(from) → \(to)"
    }
}
