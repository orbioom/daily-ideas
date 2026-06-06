import Foundation

/// Display unit for distance and pace.
enum DistanceUnit: String, CaseIterable, Identifiable {
    case km = "Kilometers", mi = "Miles"
    var id: String { rawValue }
    var short: String { self == .km ? "km" : "mi" }
    var unitMeters: Double { self == .km ? 1000 : PaceMath.mile }

    /// Distance in the chosen unit from meters.
    func distance(meters: Double) -> Double { meters / unitMeters }
    func format(meters: Double) -> String {
        let v = distance(meters: meters)
        return String(format: v < 10 ? "%.2f %@" : "%.1f %@", v, short)
    }
    /// Pace label "m:ss /unit" from seconds-per-km.
    func paceLabel(secPerKm: Double) -> String {
        guard secPerKm > 0 else { return "—" }
        let secPerUnit = self == .km ? secPerKm : secPerKm * (PaceMath.mile / 1000.0)
        return "\(PaceMath.paceClock(secPerUnit)) /\(short)"
    }
}
