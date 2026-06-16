import Foundation

/// Moon phase name derived from Sun–Moon elongation.
enum MoonPhaseName: String, CaseIterable {
    case newMoon = "New Moon"
    case waxingCrescent = "Waxing Crescent"
    case firstQuarter = "First Quarter"
    case waxingGibbous = "Waxing Gibbous"
    case fullMoon = "Full Moon"
    case waningGibbous = "Waning Gibbous"
    case lastQuarter = "Last Quarter"
    case waningCrescent = "Waning Crescent"

    var symbol: String {
        switch self {
        case .newMoon: return "moonphase.new.moon"
        case .waxingCrescent: return "moonphase.waxing.crescent"
        case .firstQuarter: return "moonphase.first.quarter"
        case .waxingGibbous: return "moonphase.waxing.gibbous"
        case .fullMoon: return "moonphase.full.moon"
        case .waningGibbous: return "moonphase.waning.gibbous"
        case .lastQuarter: return "moonphase.last.quarter"
        case .waningCrescent: return "moonphase.waning.crescent"
        }
    }
}

struct MoonPhase {
    /// Illuminated fraction [0,1].
    let illumination: Double
    /// Phase age expressed as 0…360° elongation of Moon from Sun.
    let phaseAngle: Double
    let name: MoonPhaseName
    /// True if the Moon is waxing (elongation increasing toward full).
    let isWaxing: Bool

    var illuminationPercent: Int { Int((illumination * 100).rounded()) }
}

enum MoonPhaseEngine {
    /// Compute the Moon phase for an instant from the Sun–Moon ecliptic-longitude difference.
    static func phase(at date: Date) -> MoonPhase {
        let sunLon = Ephemeris.sunLongitude(at: date)
        let moonLon = Ephemeris.moonLongitude(at: date)
        // Elongation 0…360, increasing from new → full → new.
        let elong = AstroMath.normalize360(moonLon - sunLon)
        // Illumination fraction from the phase angle (180° - elongation gives phase angle).
        let illum = (1.0 - AstroMath.cosd(elong)) / 2.0
        let waxing = elong < 180.0
        let name = phaseName(forElongation: elong)
        return MoonPhase(illumination: min(1, max(0, illum)),
                         phaseAngle: elong,
                         name: name,
                         isWaxing: waxing)
    }

    private static func phaseName(forElongation e: Double) -> MoonPhaseName {
        // 8 bins of 45°, centred so that 0=new, 90=first quarter, 180=full, 270=last quarter.
        switch e {
        case ..<22.5: return .newMoon
        case ..<67.5: return .waxingCrescent
        case ..<112.5: return .firstQuarter
        case ..<157.5: return .waxingGibbous
        case ..<202.5: return .fullMoon
        case ..<247.5: return .waningGibbous
        case ..<292.5: return .lastQuarter
        case ..<337.5: return .waningCrescent
        default: return .newMoon
        }
    }

    /// Find the next occurrences of the four principal phases after `date`.
    /// Each principal phase is a target elongation: new=0, first=90, full=180, last=270.
    /// Searches forward by minutes-resolution bisection on the elongation crossing.
    static func nextPrincipalPhases(after date: Date, count: Int = 4) -> [(name: MoonPhaseName, date: Date)] {
        let targets: [(MoonPhaseName, Double)] = [
            (.newMoon, 0), (.firstQuarter, 90), (.fullMoon, 180), (.lastQuarter, 270)
        ]
        var results: [(MoonPhaseName, Date)] = []
        // Walk forward in 6-hour steps up to ~120 days, detecting target crossings.
        let stepHours = 6.0
        let maxHours = 24.0 * 120.0
        var t = date
        var prevElong = AstroMath.normalize360(Ephemeris.moonLongitude(at: t) - Ephemeris.sunLongitude(at: t))
        var hours = 0.0
        while hours < maxHours && results.count < max(count, 8) {
            let next = t.addingTimeInterval(stepHours * 3600)
            let elong = AstroMath.normalize360(Ephemeris.moonLongitude(at: next) - Ephemeris.sunLongitude(at: next))
            for (name, target) in targets {
                if crossed(target: target, from: prevElong, to: elong) {
                    if let refined = refine(target: target, lo: t, hi: next) {
                        results.append((name, refined))
                    }
                }
            }
            prevElong = elong
            t = next
            hours += stepHours
        }
        results.sort { $0.1 < $1.1 }
        return Array(results.prefix(count))
    }

    /// True if the (cyclic) elongation crossed `target` between `a` and `b`.
    private static func crossed(target: Double, from a: Double, to b: Double) -> Bool {
        // Work relative to target so the crossing is at 0/360 boundary handling.
        let da = AstroMath.normalize360(a - target)
        let db = AstroMath.normalize360(b - target)
        // A forward crossing of the target shows as wrap-around (da large, db small).
        return da > 270 && db < 90
    }

    /// Bisection on time to pin the exact instant the elongation equals `target`.
    private static func refine(target: Double, lo: Date, hi: Date) -> Date? {
        var a = lo
        var b = hi
        for _ in 0..<40 {
            let mid = a.addingTimeInterval(b.timeIntervalSince(a) / 2)
            let em = AstroMath.normalize360(Ephemeris.moonLongitude(at: mid) - Ephemeris.sunLongitude(at: mid))
            let da = AstroMath.normalize360(em - target)
            // If still "before" the target in cyclic sense, move forward.
            if da > 180 {
                a = mid
            } else {
                b = mid
            }
        }
        return a.addingTimeInterval(b.timeIntervalSince(a) / 2)
    }
}
