import Foundation

/// The result of evaluating a measurement against the WHO reference at a given age.
struct PercentileResult {
    /// z-score (standard deviations from the median).
    let z: Double
    /// Percentile 0–100.
    let percentile: Double
    /// Interpolated median (M) at the age, in SI units.
    let median: Double

    /// Nearest labelled percentile rounded to a clean integer for display.
    var roundedPercentile: Int {
        Int((percentile).rounded())
    }
}

/// Standard percentile lines plotted on the chart, with their z-scores.
struct PercentileLine: Identifiable {
    let id: String
    let label: String
    let z: Double
}

/// WHO LMS percentile engine.
///
/// Given a measurement X at an age, with LMS parameters interpolated for that age/sex/measure:
///   z = ((X/M)^L − 1) / (L·S)   for L ≠ 0
///   z = ln(X/M) / S             for L ≈ 0
///   percentile = Φ(z)
/// Inverse (the value on a percentile curve at z):
///   X = M · (1 + L·S·z)^(1/L)   for L ≠ 0
///   X = M · exp(S·z)            for L ≈ 0
///
/// Every division and power is guarded: L≈0 falls back to the log form, M/S are validated > 0,
/// and inputs are clamped finite-and-positive so the engine never produces NaN on a user path.
enum PercentileEngine {

    /// Treat |L| below this as zero (use the log form).
    private static let lEpsilon = 1e-7

    /// The standard WHO percentile curves drawn behind a child's points.
    static let standardLines: [PercentileLine] = [
        PercentileLine(id: "p3",  label: "3rd",  z: -1.880794),
        PercentileLine(id: "p15", label: "15th", z: -1.036433),
        PercentileLine(id: "p50", label: "50th", z: 0),
        PercentileLine(id: "p85", label: "85th", z: 1.036433),
        PercentileLine(id: "p97", label: "97th", z: 1.880794)
    ]

    /// Linearly interpolate the LMS parameters for a (possibly fractional) age in months.
    /// Clamps to the table bounds so out-of-range ages reuse the nearest endpoint.
    static func interpolatedLMS(for measure: GrowthMeasure, sex: Sex, ageMonths: Double) -> LMSPoint? {
        let table = LMSTables.table(for: measure, sex: sex)
        guard let first = table.first, let last = table.last else { return nil }

        let age = max(first.ageMonths, min(last.ageMonths, ageMonths.isFinite ? ageMonths : 0))

        if age <= first.ageMonths { return first }
        if age >= last.ageMonths { return last }

        // Find the bracketing pair.
        for i in 0..<(table.count - 1) {
            let lo = table[i]
            let hi = table[i + 1]
            if age >= lo.ageMonths && age <= hi.ageMonths {
                let span = hi.ageMonths - lo.ageMonths
                guard span > 0 else { return lo }
                let t = (age - lo.ageMonths) / span
                return LMSPoint(ageMonths: age,
                                l: lo.l + (hi.l - lo.l) * t,
                                m: lo.m + (hi.m - lo.m) * t,
                                s: lo.s + (hi.s - lo.s) * t)
            }
        }
        return last
    }

    /// Evaluate a measurement value (SI units) for a child of a given sex/age.
    /// Returns nil if inputs are unusable (non-positive value, missing/invalid LMS).
    static func evaluate(value: Double,
                         measure: GrowthMeasure,
                         sex: Sex,
                         ageMonths: Double) -> PercentileResult? {
        guard value.isFinite, value > 0 else { return nil }
        guard let lms = interpolatedLMS(for: measure, sex: sex, ageMonths: ageMonths) else { return nil }
        guard lms.m > 0, lms.s > 0, lms.s.isFinite, lms.m.isFinite else { return nil }

        let ratio = value / lms.m
        guard ratio > 0, ratio.isFinite else { return nil }

        let z: Double
        if abs(lms.l) < lEpsilon {
            z = log(ratio) / lms.s
        } else {
            let powered = pow(ratio, lms.l)
            guard powered.isFinite else { return nil }
            z = (powered - 1.0) / (lms.l * lms.s)
        }
        guard z.isFinite else { return nil }

        let p = NormalDistribution.cdf(z) * 100.0
        let clampedP = min(99.9, max(0.1, p))
        return PercentileResult(z: z, percentile: clampedP, median: lms.m)
    }

    /// The reference value on a percentile curve (given z) at an age — used to draw curve lines.
    /// X = M·(1 + L·S·z)^(1/L), with the L≈0 log fallback. Guards the base of the power.
    static func value(forZ z: Double,
                      measure: GrowthMeasure,
                      sex: Sex,
                      ageMonths: Double) -> Double? {
        guard let lms = interpolatedLMS(for: measure, sex: sex, ageMonths: ageMonths) else { return nil }
        guard lms.m > 0, lms.s > 0 else { return nil }

        if abs(lms.l) < lEpsilon {
            let v = lms.m * exp(lms.s * z)
            return v.isFinite && v > 0 ? v : nil
        }

        let base = 1.0 + lms.l * lms.s * z
        guard base > 0 else { return nil }  // outside the support of the distribution
        let v = lms.m * pow(base, 1.0 / lms.l)
        return v.isFinite && v > 0 ? v : nil
    }

    /// Plain-language interpretation of a percentile for the readout card.
    static func interpretation(percentile: Double) -> String {
        let p = Int(percentile.rounded())
        switch p {
        case ..<3:    return "Below the 3rd percentile — worth a chat with your pediatrician."
        case 3..<15:  return "On the lower end of the healthy range."
        case 15..<40: return "A little below the median — comfortably typical."
        case 40..<60: return "Right around the median — bang in the middle."
        case 60..<85: return "A little above the median — comfortably typical."
        case 85..<97: return "On the higher end of the healthy range."
        default:      return "Above the 97th percentile — worth a chat with your pediatrician."
        }
    }

    /// Short ordinal label for a percentile, e.g. "50th".
    static func ordinal(_ percentile: Double) -> String {
        let p = max(1, min(99, Int(percentile.rounded())))
        let suffix: String
        switch p % 10 {
        case 1 where p != 11: suffix = "st"
        case 2 where p != 12: suffix = "nd"
        case 3 where p != 13: suffix = "rd"
        default:              suffix = "th"
        }
        return "\(p)\(suffix)"
    }
}
