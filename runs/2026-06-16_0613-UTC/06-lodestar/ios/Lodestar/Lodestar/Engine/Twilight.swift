import Foundation

/// The sky-darkness category from the Sun's altitude.
enum TwilightStage: String {
    case day = "Daytime"
    case civil = "Civil twilight"
    case nautical = "Nautical twilight"
    case astronomical = "Astronomical twilight"
    case night = "Astronomical night"

    var detail: String {
        switch self {
        case .day: return "The Sun is up — stars are not visible."
        case .civil: return "The brightest stars and planets begin to appear."
        case .nautical: return "The horizon is faint; many stars are visible."
        case .astronomical: return "Nearly dark — most deep-sky objects emerge."
        case .night: return "Fully dark skies, ideal for stargazing."
        }
    }

    var symbol: String {
        switch self {
        case .day: return "sun.max.fill"
        case .civil: return "sun.horizon.fill"
        case .nautical: return "sunset.fill"
        case .astronomical: return "moon.haze.fill"
        case .night: return "moon.stars.fill"
        }
    }
}

/// Key Sun-altitude crossing times for a local day.
struct TwilightTimes {
    var sunrise: Date?
    var sunset: Date?
    var civilDawn: Date?
    var civilDusk: Date?
    var nauticalDawn: Date?
    var nauticalDusk: Date?
    var astronomicalDawn: Date?
    var astronomicalDusk: Date?
    var currentStage: TwilightStage
}

enum TwilightEngine {
    static func stage(forSunAltitude alt: Double) -> TwilightStage {
        if alt > -0.833 { return .day }
        if alt > -6 { return .civil }
        if alt > -12 { return .nautical }
        if alt > -18 { return .astronomical }
        return .night
    }

    /// Compute twilight crossing times for the local day containing `date`.
    static func times(on date: Date, latitude: Double, longitude: Double, timeZone: TimeZone) -> TwilightTimes {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let startOfDay = cal.startOfDay(for: date)
        let stepMinutes = 5.0
        let steps = Int(24.0 * 60.0 / stepMinutes)

        // Each threshold detected both on descending (dusk) and ascending (dawn).
        var sunrise: Date?, sunset: Date?
        var civilDawn: Date?, civilDusk: Date?
        var nauticalDawn: Date?, nauticalDusk: Date?
        var astroDawn: Date?, astroDusk: Date?

        func cross(_ target: Double, prev: Double, cur: Double, lo: Date, hi: Date) -> (rising: Bool, when: Date)? {
            if prev <= target && cur > target {
                return (true, refine(target: target, lo: lo, hi: hi, latitude: latitude, longitude: longitude, rising: true))
            }
            if prev > target && cur <= target {
                return (false, refine(target: target, lo: lo, hi: hi, latitude: latitude, longitude: longitude, rising: false))
            }
            return nil
        }

        var prevAlt = RiseSetEngine.altitude(of: .sun, at: startOfDay, latitude: latitude, longitude: longitude)
        var prevTime = startOfDay
        for i in 1...steps {
            let t = startOfDay.addingTimeInterval(Double(i) * stepMinutes * 60)
            let alt = RiseSetEngine.altitude(of: .sun, at: t, latitude: latitude, longitude: longitude)

            if let c = cross(-0.833, prev: prevAlt, cur: alt, lo: prevTime, hi: t) {
                if c.rising { sunrise = sunrise ?? c.when } else { sunset = sunset ?? c.when }
            }
            if let c = cross(-6, prev: prevAlt, cur: alt, lo: prevTime, hi: t) {
                if c.rising { civilDawn = civilDawn ?? c.when } else { civilDusk = civilDusk ?? c.when }
            }
            if let c = cross(-12, prev: prevAlt, cur: alt, lo: prevTime, hi: t) {
                if c.rising { nauticalDawn = nauticalDawn ?? c.when } else { nauticalDusk = nauticalDusk ?? c.when }
            }
            if let c = cross(-18, prev: prevAlt, cur: alt, lo: prevTime, hi: t) {
                if c.rising { astroDawn = astroDawn ?? c.when } else { astroDusk = astroDusk ?? c.when }
            }
            prevAlt = alt
            prevTime = t
        }

        let curAlt = RiseSetEngine.altitude(of: .sun, at: date, latitude: latitude, longitude: longitude)
        return TwilightTimes(sunrise: sunrise, sunset: sunset,
                             civilDawn: civilDawn, civilDusk: civilDusk,
                             nauticalDawn: nauticalDawn, nauticalDusk: nauticalDusk,
                             astronomicalDawn: astroDawn, astronomicalDusk: astroDusk,
                             currentStage: stage(forSunAltitude: curAlt))
    }

    private static func refine(target: Double, lo: Date, hi: Date,
                               latitude: Double, longitude: Double, rising: Bool) -> Date {
        var a = lo
        var b = hi
        for _ in 0..<22 {
            let mid = a.addingTimeInterval(b.timeIntervalSince(a) / 2)
            let alt = RiseSetEngine.altitude(of: .sun, at: mid, latitude: latitude, longitude: longitude)
            let above = alt > target
            if rising {
                if above { b = mid } else { a = mid }
            } else {
                if above { a = mid } else { b = mid }
            }
        }
        return a.addingTimeInterval(b.timeIntervalSince(a) / 2)
    }
}
