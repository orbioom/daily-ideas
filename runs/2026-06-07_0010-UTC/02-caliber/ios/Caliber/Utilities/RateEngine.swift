import Foundation

/// The six standard timing positions plus on-wrist — the same set a watchmaker
/// regulates against, here measured from real readings instead of a timegrapher.
enum WatchPosition: String, Codable, CaseIterable, Identifiable {
    case dialUp, dialDown, crownUp, crownDown, crownLeft, crownRight, onWrist
    var id: String { rawValue }

    var label: String {
        switch self {
        case .dialUp:     return "Dial up"
        case .dialDown:   return "Dial down"
        case .crownUp:    return "Crown up"
        case .crownDown:  return "Crown down"
        case .crownLeft:  return "Crown left"
        case .crownRight: return "Crown right"
        case .onWrist:    return "On wrist"
        }
    }

    var short: String {
        switch self {
        case .dialUp: return "DU"; case .dialDown: return "DD"
        case .crownUp: return "CU"; case .crownDown: return "CD"
        case .crownLeft: return "CL"; case .crownRight: return "CR"
        case .onWrist: return "WR"
        }
    }
}

/// How a watch's accuracy reads against COSC-style bands.
enum AccuracyGrade: String {
    case chronometer = "Chronometer"
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case needsRegulation = "Needs regulation"
    case unknown = "Not enough data"

    /// Classify a daily rate in seconds/day. COSC tolerance is roughly −4/+6 s/d.
    static func from(rate: Double?) -> AccuracyGrade {
        guard let r = rate else { return .unknown }
        let a = abs(r)
        switch a {
        case ..<6:   return .chronometer
        case ..<10:  return .excellent
        case ..<20:  return .good
        case ..<40:  return .fair
        default:     return .needsRegulation
        }
    }
}

/// Pure least-squares accuracy engine. Offsets are "watch minus reference" in
/// seconds; positive means the watch is running fast (gaining).
enum RateEngine {

    /// A measurement reduced to (elapsed days, offset seconds).
    struct Sample { let days: Double; let offset: Double; let position: WatchPosition }

    /// Reduce raw measurements (any order) to samples relative to the earliest.
    static func samples(from measurements: [WatchMeasurement]) -> [Sample] {
        let sorted = measurements.sorted { $0.timestamp < $1.timestamp }
        guard let first = sorted.first else { return [] }
        return sorted.map {
            Sample(days: $0.timestamp.timeIntervalSince(first.timestamp) / 86_400.0,
                   offset: $0.offsetSeconds,
                   position: $0.position)
        }
    }

    /// Daily rate (seconds/day) via least-squares slope of offset vs elapsed days.
    /// Returns nil if there aren't two readings spanning real time.
    static func dailyRate(_ measurements: [WatchMeasurement]) -> Double? {
        let pts = samples(from: measurements)
        guard pts.count >= 2 else { return nil }
        let n = Double(pts.count)
        let sx = pts.reduce(0) { $0 + $1.days }
        let sy = pts.reduce(0) { $0 + $1.offset }
        let mx = sx / n, my = sy / n
        var num = 0.0, den = 0.0
        for p in pts {
            num += (p.days - mx) * (p.offset - my)
            den += (p.days - mx) * (p.days - mx)
        }
        guard den > 1e-9 else { return nil }
        return num / den
    }

    /// Simple two-point rate between the two most recent readings (s/day).
    static func recentRate(_ measurements: [WatchMeasurement]) -> Double? {
        let sorted = measurements.sorted { $0.timestamp < $1.timestamp }
        guard sorted.count >= 2 else { return nil }
        let a = sorted[sorted.count - 2], b = sorted[sorted.count - 1]
        let days = b.timestamp.timeIntervalSince(a.timestamp) / 86_400.0
        guard days > 1e-6 else { return nil }
        return (b.offsetSeconds - a.offsetSeconds) / days
    }

    /// Per-position rate, averaged over consecutive same-position pairs.
    /// This is the at-home analogue of a positional regulation report.
    static func positionalRates(_ measurements: [WatchMeasurement]) -> [(WatchPosition, Double)] {
        var result: [(WatchPosition, Double)] = []
        for pos in WatchPosition.allCases {
            let inPos = measurements.filter { $0.position == pos }
                .sorted { $0.timestamp < $1.timestamp }
            guard inPos.count >= 2 else { continue }
            var rates: [Double] = []
            for i in 1..<inPos.count {
                let days = inPos[i].timestamp.timeIntervalSince(inPos[i - 1].timestamp) / 86_400.0
                if days > 1e-6 {
                    rates.append((inPos[i].offsetSeconds - inPos[i - 1].offsetSeconds) / days)
                }
            }
            if !rates.isEmpty {
                result.append((pos, rates.reduce(0, +) / Double(rates.count)))
            }
        }
        return result.sorted { abs($0.1) > abs($1.1) }
    }

    /// Positional delta: spread between fastest and slowest position rate.
    static func positionalDelta(_ measurements: [WatchMeasurement]) -> Double? {
        let rates = positionalRates(measurements).map(\.1)
        guard rates.count >= 2, let mn = rates.min(), let mx = rates.max() else { return nil }
        return mx - mn
    }

    /// Projected drift over a number of days at the current rate (seconds).
    static func projectedDrift(rate: Double?, overDays: Double) -> Double? {
        guard let r = rate else { return nil }
        return r * overDays
    }
}
