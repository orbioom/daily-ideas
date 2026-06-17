import Foundation

/// Centralized @AppStorage keys so views and helpers stay in sync.
enum PrefKey {
    static let hasOnboarded = "hasOnboarded"
    static let didSeed = "didSeed"
    static let isPro = "isPro"
    static let hapticsEnabled = "hapticsEnabled"
    static let beepEnabled = "beepEnabled"
    static let unitsRaw = "unitsRaw"
    static let poolLengthRaw = "poolLengthRaw"
    static let defaultRestSeconds = "defaultRestSeconds"
    static let defaultStrokeRaw = "defaultStrokeRaw"
    static let bodyWeightKg = "bodyWeightKg"
}

/// Distance display units. Distances are stored canonically in meters.
enum DistanceUnit: String, CaseIterable, Identifiable {
    case meters
    case yards
    var id: String { rawValue }

    var label: String {
        switch self {
        case .meters: return "Meters"
        case .yards: return "Yards"
        }
    }

    var shortUnit: String {
        switch self {
        case .meters: return "m"
        case .yards: return "yd"
        }
    }

    private static let metersPerYard = 0.9144

    /// Convert canonical meters into the chosen display unit's numeric value.
    func value(fromMeters meters: Double) -> Double {
        switch self {
        case .meters: return meters
        case .yards: return meters / DistanceUnit.metersPerYard
        }
    }

    /// Convert a value expressed in this unit back to canonical meters.
    func meters(fromValue value: Double) -> Double {
        switch self {
        case .meters: return value
        case .yards: return value * DistanceUnit.metersPerYard
        }
    }
}

/// A standard pool length the user typically swims in.
enum PoolLength: String, CaseIterable, Identifiable {
    case scm25       // 25 meter
    case lcm50       // 50 meter
    case scy25       // 25 yard
    var id: String { rawValue }

    var meters: Double {
        switch self {
        case .scm25: return 25
        case .lcm50: return 50
        case .scy25: return 22.86   // 25 yards in meters
        }
    }

    var label: String {
        switch self {
        case .scm25: return "25 m (short course)"
        case .lcm50: return "50 m (long course)"
        case .scy25: return "25 yd (short course)"
        }
    }

    var shortLabel: String {
        switch self {
        case .scm25: return "25 m"
        case .lcm50: return "50 m"
        case .scy25: return "25 yd"
        }
    }
}

/// Formatting helpers for distance and time, driven by the chosen display unit.
struct UnitFormatter {
    let unit: DistanceUnit

    /// e.g. "1,500 m" — whole-number distance with unit suffix.
    func distance(_ meters: Double) -> String {
        let v = unit.value(fromMeters: max(0, meters))
        let rounded = (v).rounded()
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let number = formatter.string(from: NSNumber(value: rounded)) ?? "\(Int(rounded))"
        return "\(number) \(unit.shortUnit)"
    }

    /// Distance without the unit suffix (for axis labels etc.).
    func distanceValue(_ meters: Double) -> Double {
        unit.value(fromMeters: max(0, meters))
    }

    /// mm:ss for durations under an hour, h:mm:ss otherwise.
    static func clock(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    /// Pace per 100 expressed as mm:ss, with the unit it refers to.
    func pacePer100(_ secondsPer100: Double) -> String {
        guard secondsPer100 > 0, secondsPer100.isFinite else { return "—" }
        return "\(UnitFormatter.clock(secondsPer100)) /100\(unit.shortUnit)"
    }
}
