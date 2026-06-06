import SwiftUI

/// Measurement system. Fathom stores depth in metres and temperature in °C
/// internally; this converts for display and entry.
enum UnitSystem: String, CaseIterable, Identifiable {
    case metric, imperial
    var id: String { rawValue }
    var label: String { self == .metric ? "Metric (m, °C)" : "Imperial (ft, °F)" }
    var depthUnit: String { self == .metric ? "m" : "ft" }
    var tempUnit: String { self == .metric ? "°C" : "°F" }

    func depthOut(_ m: Double) -> Double { self == .metric ? m : m * 3.28084 }
    func depthToM(_ v: Double) -> Double { self == .metric ? v : v / 3.28084 }
    func tempOut(_ c: Double) -> Double { self == .metric ? c : c * 9 / 5 + 32 }
    func tempToC(_ v: Double) -> Double { self == .metric ? v : (v - 32) * 5 / 9 }
}

/// Where the dive happened.
enum DiveType: String, Codable, CaseIterable, Identifiable {
    case boat, shore, drift, wreck, night, cave, training, other
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .boat: return "ferry"
        case .shore: return "beach.umbrella"
        case .drift: return "wind"
        case .wreck: return "shippingbox"
        case .night: return "moon.stars"
        case .cave: return "mountain.2"
        case .training: return "graduationcap"
        case .other: return "water.waves"
        }
    }
}

/// Breathing gas: air or a nitrox mix with an oxygen fraction.
struct BreathingGas: Equatable {
    var oxygenPercent: Int   // 21 = air
    var isAir: Bool { oxygenPercent == 21 }
    var label: String { isAir ? "Air" : "EAN\(oxygenPercent)" }
    static let air = BreathingGas(oxygenPercent: 21)
}
