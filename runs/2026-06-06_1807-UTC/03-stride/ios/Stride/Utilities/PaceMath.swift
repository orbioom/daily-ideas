import Foundation

/// Running performance math: Riegel race prediction and Daniels-style VDOT
/// training paces. Pure value type; every function guards against bad input.
enum PaceMath {

    // MARK: - Distance presets (meters)

    static let mile = 1609.344
    static let standardDistances: [(name: String, meters: Double)] = [
        ("1500 m", 1500), ("Mile", mile), ("3 km", 3000), ("5 km", 5000),
        ("8 km", 8000), ("10 km", 10000), ("12 km", 12000), ("15 km", 15000),
        ("10 mi", 10 * mile), ("Half", 21097.5), ("30 km", 30000), ("Marathon", 42195)
    ]

    // MARK: - Riegel prediction

    /// Predict the time for `d2` meters from a known `t1`/`d1` result.
    /// T2 = T1 · (D2/D1)^exponent. Default exponent 1.06 (Riegel).
    static func riegel(t1Sec: Double, d1: Double, d2: Double, exponent: Double = 1.06) -> Double {
        guard t1Sec > 0, d1 > 0, d2 > 0 else { return 0 }
        return t1Sec * pow(d2 / d1, exponent)
    }

    // MARK: - VDOT (Jack Daniels)

    /// Oxygen cost (ml/kg/min) of running at velocity v (m/min).
    static func vo2(atVelocity v: Double) -> Double {
        -4.60 + 0.182258 * v + 0.000104 * v * v
    }

    /// Fraction of VO2max sustainable for a race of `t` minutes.
    static func percentMax(timeMin t: Double) -> Double {
        0.8 + 0.1894393 * exp(-0.012778 * t) + 0.2989558 * exp(-0.1932605 * t)
    }

    /// VDOT for a race of `distance` meters run in `timeSec` seconds.
    static func vdot(distance: Double, timeSec: Double) -> Double {
        guard distance > 0, timeSec > 0 else { return 0 }
        let tMin = timeSec / 60.0
        let v = distance / tMin                       // m/min
        let raw = vo2(atVelocity: v) / percentMax(timeMin: tMin)
        return max(0, raw)
    }

    /// Invert the VO2/velocity quadratic to find velocity (m/min) for a VO2 target.
    static func velocity(forVO2 target: Double) -> Double {
        // 0.000104 v² + 0.182258 v + (-4.60 - target) = 0
        let a = 0.000104, b = 0.182258, c = -4.60 - target
        let disc = b * b - 4 * a * c
        guard disc >= 0, a != 0 else { return 0 }
        let v = (-b + sqrt(disc)) / (2 * a)
        return max(0, v)
    }

    /// A named training intensity with its fraction of VDOT (as a VO2 target).
    enum Zone: String, CaseIterable, Identifiable {
        case easy = "Easy", marathon = "Marathon", threshold = "Threshold"
        case interval = "Interval", repetition = "Repetition"
        var id: String { rawValue }
        var fraction: Double {
            switch self {
            case .easy: return 0.70; case .marathon: return 0.84; case .threshold: return 0.88
            case .interval: return 0.975; case .repetition: return 1.07
            }
        }
        var blurb: String {
            switch self {
            case .easy: return "Conversational base & recovery"
            case .marathon: return "Goal marathon effort"
            case .threshold: return "Comfortably hard, ~1-hour race effort"
            case .interval: return "Hard, ~3–5 min reps at VO2max"
            case .repetition: return "Fast, short reps for speed & economy"
            }
        }
        var color: String { rawValue }
    }

    /// Training pace (seconds per km) for a zone at a given VDOT.
    static func paceSecPerKm(vdot: Double, zone: Zone) -> Double {
        guard vdot > 0 else { return 0 }
        let v = velocity(forVO2: vdot * zone.fraction)   // m/min
        guard v > 0 else { return 0 }
        return (1000.0 / v) * 60.0
    }

    // MARK: - Splits

    /// Even or negatively-split per-unit cumulative times for a target finish.
    /// `unitMeters` is 1000 (km) or `mile`. `negativeSplitSec` shifts effort to the
    /// back half: the first half runs that many seconds *slower*, the second faster.
    static func splits(distance: Double, totalSec: Double, unitMeters: Double,
                       negativeSplitSec: Double = 0) -> [(unit: Int, cumulative: Double, split: Double)] {
        guard distance > 0, totalSec > 0, unitMeters > 0 else { return [] }
        let fullUnits = Int((distance / unitMeters).rounded(.down))
        let remainder = distance - Double(fullUnits) * unitMeters
        let totalUnits = fullUnits + (remainder > 1 ? 1 : 0)
        guard totalUnits > 0 else { return [] }

        let basePerUnit = totalSec / (distance / unitMeters)
        // Linear progression from slower to faster so the average stays on target.
        var rows: [(Int, Double, Double)] = []
        var cumulative = 0.0
        for i in 0..<totalUnits {
            let isPartial = (i == fullUnits && remainder > 1)
            let unitFraction = isPartial ? (remainder / unitMeters) : 1.0
            // progress from -1 (start) to +1 (end)
            let prog = totalUnits > 1 ? (Double(i) / Double(totalUnits - 1)) * 2 - 1 : 0
            let adjust = -prog * (negativeSplitSec / 2.0)   // start slower, finish faster
            let split = (basePerUnit + adjust) * unitFraction
            cumulative += split
            rows.append((i + 1, cumulative, split))
        }
        // Renormalize cumulative to hit exactly totalSec (rounding safety).
        if let last = rows.last?.1, last > 0 {
            let scale = totalSec / last
            rows = rows.map { ($0.0, $0.1 * scale, $0.2 * scale) }
        }
        return rows.map { (unit: $0.0, cumulative: $0.1, split: $0.2) }
    }

    // MARK: - Formatting

    /// Format seconds as h:mm:ss (drops the hour when zero) — for durations.
    static func clock(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "—" }
        let s = Int(seconds.rounded())
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec)
                     : String(format: "%d:%02d", m, sec)
    }

    /// Format a pace (sec per unit) as m:ss.
    static func paceClock(_ secPerUnit: Double) -> String {
        guard secPerUnit.isFinite, secPerUnit > 0 else { return "—" }
        let s = Int(secPerUnit.rounded())
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
