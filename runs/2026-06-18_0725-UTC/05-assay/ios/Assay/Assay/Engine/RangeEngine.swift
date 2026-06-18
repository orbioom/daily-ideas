import SwiftUI

/// Classification of a value against its reference and optimal ranges.
enum MarkerStatus: String {
    case low = "Low"
    case belowOptimal = "Below Optimal"
    case optimal = "Optimal"
    case inRange = "In Range"
    case high = "High"

    var color: Color {
        switch self {
        case .optimal: return Theme.good
        case .inRange: return Theme.okay
        case .belowOptimal: return Theme.warn
        case .low, .high: return Theme.bad
        }
    }

    var symbol: String {
        switch self {
        case .optimal: return "checkmark.seal.fill"
        case .inRange: return "checkmark.circle"
        case .belowOptimal: return "minus.circle"
        case .low: return "arrow.down.circle.fill"
        case .high: return "arrow.up.circle.fill"
        }
    }

    /// True when the value sits outside the standard reference range.
    var isOutOfRange: Bool { self == .low || self == .high }
    var isOptimal: Bool { self == .optimal }
}

/// Severity 0 (fine) … 3 (notably out of range) for sorting/alerts.
enum MarkerSeverity: Int, Comparable {
    case none = 0, mild = 1, moderate = 2, marked = 3
    static func < (l: MarkerSeverity, r: MarkerSeverity) -> Bool { l.rawValue < r.rawValue }
}

struct RangeAssessment {
    let status: MarkerStatus
    let severity: MarkerSeverity
    /// Position 0…1 of the value across the standard range span (clamped).
    let position: Double
    /// Canonical value assessed.
    let canonicalValue: Double
}

/// Pure, fully-guarded classification engine. All ranges/divisions are guarded.
enum RangeEngine {

    /// Assess a recorded value. `rawUnit` lets us normalize to canonical first.
    static func assess(
        marker: Biomarker,
        rawValue: Double,
        rawUnit: String,
        sex: BiologicalSex
    ) -> RangeAssessment {
        let canonical = UnitConverter.toCanonical(value: rawValue, rawUnit: rawUnit, marker: marker)
        return assessCanonical(marker: marker, canonical: canonical, sex: sex)
    }

    static func assessCanonical(
        marker: Biomarker,
        canonical: Double,
        sex: BiologicalSex
    ) -> RangeAssessment {
        let std = marker.standard.range(for: sex)
        let opt = marker.optimal.range(for: sex)

        let status = classify(canonical: canonical, std: std, opt: opt, direction: marker.direction)
        let severity = severity(for: status, canonical: canonical, std: std, marker: marker)
        let pos = position(canonical: canonical, marker: marker, std: std)

        return RangeAssessment(status: status, severity: severity, position: pos, canonicalValue: canonical)
    }

    // MARK: - Classification

    private static func classify(
        canonical v: Double,
        std: ClinicalRange,
        opt: ClinicalRange,
        direction: MarkerDirection
    ) -> MarkerStatus {
        // Outside standard range first.
        if let lo = std.low, v < lo { return .low }
        if let hi = std.high, v > hi { return .high }

        // Inside standard range — is it inside optimal?
        let aboveOptLow = opt.low.map { v >= $0 } ?? true
        let belowOptHigh = opt.high.map { v <= $0 } ?? true
        if aboveOptLow && belowOptHigh { return .optimal }

        // In standard range but outside optimal. Distinguish "below optimal"
        // (a soft, improvable signal) from generic in-range.
        switch direction {
        case .higherBetter:
            return .belowOptimal // below the optimal floor
        case .higherWorse:
            return .inRange // above optimal ceiling but within standard
        case .midOptimal:
            return .inRange
        }
    }

    // MARK: - Severity

    private static func severity(
        for status: MarkerStatus,
        canonical v: Double,
        std: ClinicalRange,
        marker: Biomarker
    ) -> MarkerSeverity {
        switch status {
        case .optimal: return .none
        case .inRange: return .none
        case .belowOptimal: return .mild
        case .low:
            guard let lo = std.low else { return .moderate }
            return distanceSeverity(value: lo - v, reference: lo, marker: marker)
        case .high:
            guard let hi = std.high else { return .moderate }
            return distanceSeverity(value: v - hi, reference: hi, marker: marker)
        }
    }

    /// Maps how far outside the bound a value is (relative to the marker's
    /// display span) into a severity. Division is guarded.
    private static func distanceSeverity(value overshoot: Double, reference: Double, marker: Biomarker) -> MarkerSeverity {
        let span = marker.displayMax - marker.displayMin
        guard span > 0, overshoot.isFinite else { return .moderate }
        let frac = overshoot / span
        if frac >= 0.20 { return .marked }
        if frac >= 0.08 { return .moderate }
        return .mild
    }

    // MARK: - Band position (0…1 across the standard window)

    /// Position of the value across a finite window built from the standard
    /// range (falling back to the marker's display bounds for open ends).
    /// Always returns a value in 0…1. Division guarded.
    static func position(canonical v: Double, marker: Biomarker, std: ClinicalRange) -> Double {
        let (lo, hi) = std.span(fallbackLow: marker.displayMin, fallbackHigh: marker.displayMax)
        // Pad the window a little so values exactly at the bound aren't at 0/1.
        let pad = (hi - lo) * 0.15
        let wLo = lo - pad
        let wHi = hi + pad
        let width = wHi - wLo
        guard width > 0, v.isFinite else { return 0.5 }
        let raw = (v - wLo) / width
        return Swift.min(1, Swift.max(0, raw))
    }

    /// Normalized positions of the optimal & standard band edges across the
    /// same window — used to draw the colored bands behind the marker dot.
    static func bandStops(marker: Biomarker, sex: BiologicalSex) -> BandStops {
        let std = marker.standard.range(for: sex)
        let opt = marker.optimal.range(for: sex)
        let (lo, hi) = std.span(fallbackLow: marker.displayMin, fallbackHigh: marker.displayMax)
        let pad = (hi - lo) * 0.15
        let wLo = lo - pad
        let wHi = hi + pad
        let width = wHi - wLo
        func norm(_ x: Double?) -> Double? {
            guard let x, width > 0 else { return nil }
            return Swift.min(1, Swift.max(0, (x - wLo) / width))
        }
        return BandStops(
            stdLow: norm(std.low),
            stdHigh: norm(std.high),
            optLow: norm(opt.low),
            optHigh: norm(opt.high)
        )
    }
}

/// Normalized (0…1) edge positions for the band visualization.
struct BandStops {
    let stdLow: Double?
    let stdHigh: Double?
    let optLow: Double?
    let optHigh: Double?
}
