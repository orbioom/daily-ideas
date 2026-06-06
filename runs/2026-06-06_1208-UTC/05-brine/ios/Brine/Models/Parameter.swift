import SwiftUI

/// A water-chemistry parameter with reef-keeping target ranges.
/// Canonical storage units: temperature in °C, salinity in ppt, everything
/// else in its hobby-standard unit (dKH, ppm). Display conversion happens in Fmt.
enum WaterParameter: String, Codable, CaseIterable, Identifiable {
    case temperature, ph, salinity, alkalinity, calcium, magnesium, nitrate, phosphate, ammonia

    var id: String { rawValue }

    var name: String {
        switch self {
        case .temperature: return "Temperature"
        case .ph: return "pH"
        case .salinity: return "Salinity"
        case .alkalinity: return "Alkalinity"
        case .calcium: return "Calcium"
        case .magnesium: return "Magnesium"
        case .nitrate: return "Nitrate (NO₃)"
        case .phosphate: return "Phosphate (PO₄)"
        case .ammonia: return "Ammonia (NH₃)"
        }
    }
    var shortName: String {
        switch self {
        case .temperature: return "Temp"
        case .alkalinity: return "Alk"
        case .calcium: return "Ca"
        case .magnesium: return "Mg"
        case .nitrate: return "NO₃"
        case .phosphate: return "PO₄"
        case .ammonia: return "NH₃"
        default: return name
        }
    }
    /// Canonical unit label (before display conversion).
    var unit: String {
        switch self {
        case .temperature: return "°C"
        case .ph: return ""
        case .salinity: return "ppt"
        case .alkalinity: return "dKH"
        case .calcium, .magnesium, .nitrate, .phosphate, .ammonia: return "ppm"
        }
    }
    var decimals: Int {
        switch self {
        case .ph: return 2
        case .phosphate: return 2
        case .alkalinity, .salinity: return 1
        case .nitrate, .ammonia: return 1
        default: return 0
        }
    }
    /// Ideal reef range (canonical units).
    var ideal: ClosedRange<Double> {
        switch self {
        case .temperature: return 25...27
        case .ph: return 7.9...8.4
        case .salinity: return 33...35
        case .alkalinity: return 8...10
        case .calcium: return 400...450
        case .magnesium: return 1300...1400
        case .nitrate: return 2...10
        case .phosphate: return 0.03...0.10
        case .ammonia: return 0...0
        }
    }
    /// Acceptable (safe) range — outside this is flagged out-of-range.
    var safe: ClosedRange<Double> {
        switch self {
        case .temperature: return 24...28
        case .ph: return 7.7...8.5
        case .salinity: return 32...36
        case .alkalinity: return 7...12
        case .calcium: return 380...480
        case .magnesium: return 1250...1450
        case .nitrate: return 0...20
        case .phosphate: return 0...0.2
        case .ammonia: return 0...0.05
        }
    }
    /// Sensible step for entry steppers.
    var typicalMax: Double {
        switch self {
        case .temperature: return 35
        case .ph: return 9
        case .salinity: return 40
        case .alkalinity: return 15
        case .calcium: return 600
        case .magnesium: return 1600
        case .nitrate: return 100
        case .phosphate: return 1
        case .ammonia: return 2
        }
    }
}

/// In-range / borderline / out-of-range classification.
enum ParamStatus {
    case good, watch, bad
    var tint: Color {
        switch self {
        case .good: return Brand.live
        case .watch: return Brand.warn
        case .bad: return Brand.danger
        }
    }
    var label: String {
        switch self {
        case .good: return "In range"
        case .watch: return "Watch"
        case .bad: return "Out of range"
        }
    }
}

extension WaterParameter {
    /// Classify a canonical value against the ideal/safe ranges.
    func status(for value: Double) -> ParamStatus {
        if !safe.contains(value) { return .bad }
        if ideal.contains(value) { return .good }
        return .watch
    }
}
