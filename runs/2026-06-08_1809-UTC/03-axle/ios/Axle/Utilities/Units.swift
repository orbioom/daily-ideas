import Foundation

enum DistanceUnit: String, CaseIterable, Identifiable {
    case km, mi
    var id: String { rawValue }
    var label: String { self == .km ? "km" : "mi" }
    func fromKm(_ km: Double) -> Double { self == .km ? km : km / 1.609344 }
    func toKm(_ value: Double) -> Double { self == .km ? value : value * 1.609344 }
}

enum VolumeUnit: String, CaseIterable, Identifiable {
    case liter, gallon
    var id: String { rawValue }
    var label: String { self == .liter ? "L" : "gal" }
    func fromLiters(_ l: Double) -> Double { self == .liter ? l : l / 3.785411784 }
    func toLiters(_ value: Double) -> Double { self == .liter ? value : value * 3.785411784 }
}

/// Formatting helpers that respect the user's chosen units. Canonical storage
/// is always km + liters; conversions happen only for display/entry.
struct UnitFormatter {
    let distance: DistanceUnit
    let volume: VolumeUnit
    let currencyCode: String

    func distanceString(km: Double, decimals: Int = 0) -> String {
        let v = distance.fromKm(km)
        return "\(formatted(v, decimals: decimals)) \(distance.label)"
    }

    func volumeString(liters: Double, decimals: Int = 1) -> String {
        let v = volume.fromLiters(liters)
        return "\(formatted(v, decimals: decimals)) \(volume.label)"
    }

    func money(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    /// Economy string in the convention matching the chosen units:
    /// L/100km for metric, mpg for imperial.
    func economyString(km: Double, liters: Double) -> String {
        guard km > 0, liters > 0 else { return "—" }
        if distance == .km {
            let l100 = liters / (km / 100)
            return String(format: "%.1f L/100km", l100)
        } else {
            let miles = km / 1.609344
            let gallons = liters / 3.785411784
            return String(format: "%.1f mpg", miles / gallons)
        }
    }

    private func formatted(_ value: Double, decimals: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = decimals
        f.minimumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.\(decimals)f", value)
    }
}
