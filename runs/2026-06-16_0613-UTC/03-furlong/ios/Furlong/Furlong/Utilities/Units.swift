import Foundation

/// Distance is stored canonically in MILES throughout the model.
/// This helper converts to the user-facing unit for display & input parsing.
enum DistanceUnit: String, CaseIterable, Identifiable {
    case miles = "Miles"
    case kilometers = "Kilometers"

    var id: String { rawValue }

    var shortLabel: String { self == .miles ? "mi" : "km" }

    /// Miles per one display unit.
    private var milesPerUnit: Double { self == .miles ? 1.0 : 0.621371 }

    /// Convert canonical miles -> display value in this unit.
    func fromMiles(_ miles: Double) -> Double { miles / milesPerUnit }

    /// Convert a value expressed in this unit -> canonical miles.
    func toMiles(_ value: Double) -> Double { value * milesPerUnit }
}
