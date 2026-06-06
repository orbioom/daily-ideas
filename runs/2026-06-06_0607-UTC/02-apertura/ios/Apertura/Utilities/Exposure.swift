import Foundation

/// The stop increment a calculation snaps to. Pure, value-type configuration.
enum StopIncrement: String, CaseIterable, Identifiable, Codable, Sendable {
    case third, half, full

    var id: String { rawValue }

    var title: String {
        switch self {
        case .third: return "Third"
        case .half:  return "Half"
        case .full:  return "Full"
        }
    }

    /// Stops per step: ⅓, ½, or 1 full stop.
    var stepInStops: Double {
        switch self {
        case .third: return 1.0 / 3.0
        case .half:  return 1.0 / 2.0
        case .full:  return 1.0
        }
    }

    var symbol: String {
        switch self {
        case .third: return "⅓"
        case .half:  return "½"
        case .full:  return "1"
        }
    }
}

/// A solved equivalent exposure: an aperture/shutter pair that yields the same EV.
struct EquivalentExposure: Identifiable, Hashable, Sendable {
    var aperture: Double
    var shutterSeconds: Double

    /// Stable identity from the rounded pair so SwiftUI lists are well-behaved.
    var id: String { "\(aperture.rounded(to: 4))|\(shutterSeconds.rounded(to: 6))" }
}

/// A qualitative, honest indicator level. Never claims to be a meter.
enum GuidanceLevel: String, Sendable {
    case low, medium, high

    var label: String {
        switch self {
        case .low:    return "Low"
        case .medium: return "Moderate"
        case .high:   return "High"
        }
    }
}

/// PURE, testable photometric core. No SwiftUI, no SwiftData, no I/O.
///
/// Conventions:
/// - aperture `N` is an f-number (e.g. 2.8). Must be > 0.
/// - shutter `t` is in seconds (e.g. 0.004 for 1/250). Must be > 0.
/// - ISO `S` is film/sensor speed (e.g. 100, 400). Must be > 0.
///
/// EV is expressed at ISO 100 unless `ev(...)` is given an ISO, in which case it is
/// adjusted by `log2(S / 100)`. The relationship is `EV100 = log2(N² / t)`.
struct Exposure: Equatable, Sendable {

    // MARK: - Canonical scales

    /// Whole-stop aperture scale (f-numbers). Each step is one stop (×√2).
    static let fullStopApertures: [Double] = [
        1.0, 1.4, 2.0, 2.8, 4.0, 5.6, 8.0, 11.0, 16.0, 22.0, 32.0, 45.0, 64.0
    ]

    /// Whole-stop shutter speeds in seconds (each step halves time = one stop).
    static let fullStopShutters: [Double] = [
        30, 15, 8, 4, 2, 1,
        1.0/2, 1.0/4, 1.0/8, 1.0/15, 1.0/30, 1.0/60,
        1.0/125, 1.0/250, 1.0/500, 1.0/1000, 1.0/2000, 1.0/4000, 1.0/8000
    ]

    /// Common ISO film/sensor speeds.
    static let commonISOs: [Double] = [25, 50, 100, 200, 400, 800, 1600, 3200, 6400]

    // MARK: - Core EV math

    /// EV at ISO 100 for the given aperture and shutter. Guarded: returns nil on
    /// non-positive inputs so callers never divide by zero or take log of ≤ 0.
    static func ev100(aperture N: Double, shutterSeconds t: Double) -> Double? {
        guard N > 0, t > 0 else { return nil }
        let ratio = (N * N) / t
        guard ratio > 0 else { return nil }
        return log2(ratio)
    }

    /// EV adjusted for ISO. `EV = log2(N²/t) + log2(S/100)`.
    /// Returns nil on any non-positive input.
    static func ev(aperture N: Double, shutterSeconds t: Double, iso S: Double) -> Double? {
        guard S > 0, let base = ev100(aperture: N, shutterSeconds: t) else { return nil }
        return base + log2(S / 100.0)
    }

    // MARK: - Solving the missing leg

    /// Solve aperture given shutter and a target EV (at the given ISO).
    /// `N = sqrt(t · 2^EV100)` where `EV100 = EV - log2(S/100)`.
    static func solveAperture(shutterSeconds t: Double, targetEV: Double, iso S: Double) -> Double? {
        guard t > 0, S > 0 else { return nil }
        let ev100 = targetEV - log2(S / 100.0)
        let value = t * pow(2.0, ev100)
        guard value > 0 else { return nil }
        let n = (value).squareRoot()
        guard n.isFinite, n > 0 else { return nil }
        return n
    }

    /// Solve shutter (seconds) given aperture and a target EV (at the given ISO).
    /// `t = N² / 2^EV100`.
    static func solveShutter(aperture N: Double, targetEV: Double, iso S: Double) -> Double? {
        guard N > 0, S > 0 else { return nil }
        let ev100 = targetEV - log2(S / 100.0)
        let denom = pow(2.0, ev100)
        guard denom > 0 else { return nil }
        let t = (N * N) / denom
        guard t.isFinite, t > 0 else { return nil }
        return t
    }

    /// Solve the ISO needed so the given aperture/shutter hit a target EV.
    /// `S = 100 · 2^(EV - EV100base)`.
    static func solveISO(aperture N: Double, shutterSeconds t: Double, targetEV: Double) -> Double? {
        guard let base = ev100(aperture: N, shutterSeconds: t) else { return nil }
        let s = 100.0 * pow(2.0, targetEV - base)
        guard s.isFinite, s > 0 else { return nil }
        return s
    }

    // MARK: - Stop snapping

    /// Snap an aperture to the nearest valid f-number on the chosen increment.
    /// Apertures advance by √2 per full stop, so we work in stops-from-f/1.
    static func snapAperture(_ N: Double, increment: StopIncrement) -> Double? {
        guard N > 0 else { return nil }
        // stops above f/1: N = 2^(stops/2)  ->  stops = 2·log2(N)
        let stops = 2.0 * log2(N)
        let snapped = snapToStep(stops, step: increment.stepInStops)
        let result = pow(2.0, snapped / 2.0)
        guard result.isFinite, result > 0 else { return nil }
        return result
    }

    /// Snap a shutter time to the nearest valid value on the chosen increment.
    /// Shutter halves per full stop, so stops = -log2(t) relative to 1 second.
    static func snapShutter(_ t: Double, increment: StopIncrement) -> Double? {
        guard t > 0 else { return nil }
        let stops = -log2(t)
        let snapped = snapToStep(stops, step: increment.stepInStops)
        let result = pow(2.0, -snapped)
        guard result.isFinite, result > 0 else { return nil }
        return result
    }

    /// Snap a continuous stops value to the nearest multiple of `step`.
    static func snapToStep(_ value: Double, step: Double) -> Double {
        guard step > 0 else { return value }
        return (value / step).rounded() * step
    }

    // MARK: - Stop difference

    /// How many stops `value` differs from `reference` for the same axis kind.
    /// Positive means brighter exposure (more light). Useful for "you're N stops under".
    /// For aperture: opening up (smaller N) = +stops. For shutter: slower (larger t) = +stops.
    static func stopsBetweenEV(_ ev: Double, target: Double) -> Double {
        // A higher EV needs LESS light; being under target by `target - ev` stops.
        target - ev
    }

    // MARK: - Equivalent exposure enumeration

    /// Enumerate aperture/shutter pairs that all yield `targetEV` at the given ISO,
    /// stepping the aperture across the canonical full-stop range on the chosen increment.
    /// Every returned pair is guaranteed positive and finite.
    static func equivalents(targetEV: Double,
                            iso S: Double,
                            increment: StopIncrement,
                            apertureRange: ClosedRange<Double> = 1.0...32.0) -> [EquivalentExposure] {
        guard S > 0, apertureRange.lowerBound > 0 else { return [] }
        var results: [EquivalentExposure] = []

        // Walk apertures in stop steps from the low end to the high end.
        let startStops = 2.0 * log2(apertureRange.lowerBound)
        let endStops = 2.0 * log2(apertureRange.upperBound)
        let step = increment.stepInStops
        guard step > 0, endStops >= startStops else { return [] }

        var stops = startStops
        // Snap start to the grid so values are clean (f/1, f/1.4, ...).
        stops = snapToStep(stops, step: step)
        if stops < startStops { stops += step }

        var guardCount = 0
        while stops <= endStops + 1e-9 && guardCount < 200 {
            guardCount += 1
            let n = pow(2.0, stops / 2.0)
            if n > 0, let t = solveShutter(aperture: n, targetEV: targetEV, iso: S) {
                // Only keep usefully bounded shutter speeds.
                if t >= 1.0/16000 && t <= 60 {
                    results.append(EquivalentExposure(aperture: n, shutterSeconds: t))
                }
            }
            stops += step
        }
        return results
    }

    // MARK: - Qualitative guidance (honest, clearly not a meter)

    /// Depth-of-field guidance: a wider aperture (small N) and longer focal length give
    /// a shallower depth of field. Returns a level + plain-language note.
    static func depthOfField(aperture N: Double, focalLengthMM: Double) -> GuidanceLevel {
        guard N > 0, focalLengthMM > 0 else { return .medium }
        // Heuristic "shallowness" score: more shallow as N shrinks and focal grows.
        let score = (focalLengthMM / 50.0) / N
        if score >= 0.9 { return .high }      // very shallow DoF
        if score >= 0.35 { return .medium }
        return .low                            // deep DoF
    }

    /// Motion-blur risk from shutter time and focal length (longer lens magnifies shake).
    /// The classic "1/focal" rule informs the threshold.
    static func motionBlurRisk(shutterSeconds t: Double, focalLengthMM: Double) -> GuidanceLevel {
        guard t > 0, focalLengthMM > 0 else { return .medium }
        let safeHandheld = 1.0 / focalLengthMM   // seconds
        if t > safeHandheld * 4 { return .high }
        if t > safeHandheld { return .medium }
        return .low
    }

    /// Noise/grain guidance purely from ISO (qualitative).
    static func noise(iso S: Double) -> GuidanceLevel {
        guard S > 0 else { return .medium }
        if S >= 1600 { return .high }
        if S >= 400 { return .medium }
        return .low
    }

    // MARK: - Formatting helpers (pure)

    /// Human f-number string, e.g. "f/2.8" or "f/11".
    static func apertureString(_ N: Double) -> String {
        guard N > 0, N.isFinite else { return "—" }
        if N >= 10 {
            return "f/\(Int(N.rounded()))"
        }
        // One decimal for the classic in-between stops (1.4, 2.8, 5.6).
        let rounded = (N * 10).rounded() / 10
        if rounded == rounded.rounded() {
            return "f/\(Int(rounded))"
        }
        return "f/\(String(format: "%.1f", rounded))"
    }

    /// Human shutter string, e.g. "1/250", "1/2", "2\"" (seconds), "30\"".
    static func shutterString(_ t: Double) -> String {
        guard t > 0, t.isFinite else { return "—" }
        if t >= 1 {
            // Whole seconds, drop trailing .0
            if t == t.rounded() {
                return "\(Int(t.rounded()))\""
            }
            return "\(String(format: "%.1f", t))\""
        }
        // Fractional: render as 1/x with x to the nearest standard-ish integer.
        let denom = (1.0 / t).rounded()
        guard denom.isFinite, denom > 0 else { return "—" }
        return "1/\(Int(denom))"
    }

    /// EV formatted to one decimal.
    static func evString(_ ev: Double) -> String {
        guard ev.isFinite else { return "—" }
        return String(format: "%.1f", ev)
    }

    /// "N stops under/over" plain-language readout, snapped to a clean fraction.
    static func stopsDescription(_ stops: Double) -> String {
        let magnitude = abs(stops)
        guard magnitude.isFinite else { return "—" }
        if magnitude < 0.05 { return "On target" }
        let direction = stops > 0 ? "under" : "over"
        let fraction = fractionString(magnitude)
        return "\(fraction) stop\(magnitude >= 1.5 ? "s" : "") \(direction)"
    }

    /// Render a stop magnitude as whole + ⅓/½/⅔ fraction, e.g. 1.333 -> "1⅓".
    static func fractionString(_ value: Double) -> String {
        guard value.isFinite else { return "0" }
        let whole = Int(value)
        let frac = value - Double(whole)
        let glyph: String
        switch (frac * 12).rounded() {
        case 0:  glyph = ""
        case 4:  glyph = "⅓"
        case 6:  glyph = "½"
        case 8:  glyph = "⅔"
        case 12: return "\(whole + 1)"
        default:
            // Fall back to a rounded decimal for off-grid values.
            return String(format: "%.1f", value)
        }
        if whole == 0 { return glyph.isEmpty ? "0" : glyph }
        return glyph.isEmpty ? "\(whole)" : "\(whole)\(glyph)"
    }
}

extension Double {
    /// Round to a fixed number of decimal places (used for stable identities).
    func rounded(to places: Int) -> Double {
        let p = pow(10.0, Double(places))
        return (self * p).rounded() / p
    }
}
