import Foundation

/// Distance display unit. QSO distances are computed in km, then formatted.
enum DistanceUnit: String, CaseIterable, Identifiable {
    case km = "Kilometers", mi = "Miles"
    var id: String { rawValue }
    var short: String { self == .km ? "km" : "mi" }

    func format(km: Double) -> String {
        let v = self == .km ? km : km * 0.621371
        return "\(Int(v.rounded())) \(short)"
    }
    func value(km: Double) -> Double { self == .km ? km : km * 0.621371 }
}
