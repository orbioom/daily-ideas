import Foundation

enum Prayer: String, CaseIterable, Codable, Identifiable {
    case fajr, sunrise, dhuhr, asr, maghrib, isha

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fajr: return "Fajr"
        case .sunrise: return "Sunrise"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        }
    }

    var arabicName: String {
        switch self {
        case .fajr: return "الفجر"
        case .sunrise: return "الشروق"
        case .dhuhr: return "الظهر"
        case .asr: return "العصر"
        case .maghrib: return "المغرب"
        case .isha: return "العشاء"
        }
    }

    var symbol: String {
        switch self {
        case .fajr: return "sunrise"
        case .sunrise: return "sun.horizon"
        case .dhuhr: return "sun.max"
        case .asr: return "sun.min"
        case .maghrib: return "sunset"
        case .isha: return "moon.stars"
        }
    }

    /// The five obligatory prayers (sunrise is informational only).
    static var obligatory: [Prayer] { [.fajr, .dhuhr, .asr, .maghrib, .isha] }
}

enum CalculationMethod: String, CaseIterable, Identifiable {
    case mwl, isna, egyptian, ummAlQura, karachi

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mwl: return "Muslim World League"
        case .isna: return "ISNA (North America)"
        case .egyptian: return "Egyptian Authority"
        case .ummAlQura: return "Umm al-Qura (Makkah)"
        case .karachi: return "Univ. of Karachi"
        }
    }

    var fajrAngle: Double {
        switch self {
        case .mwl: return 18
        case .isna: return 15
        case .egyptian: return 19.5
        case .ummAlQura: return 18.5
        case .karachi: return 18
        }
    }

    /// Isha is either depression-angle based or a fixed offset after maghrib.
    var ishaAngle: Double? {
        switch self {
        case .mwl: return 17
        case .isna: return 15
        case .egyptian: return 17.5
        case .ummAlQura: return nil
        case .karachi: return 18
        }
    }

    var ishaMinutesAfterMaghrib: Double { 90 } // used only when ishaAngle == nil
}

struct PrayerTimes {
    let day: Date          // midnight in the city's timezone
    let times: [Prayer: Date]
    let timeZone: TimeZone

    func time(for prayer: Prayer) -> Date? { times[prayer] }
}

/// Solar-geometry prayer time calculator (port of the standard praytimes
/// algorithm: low-precision NOAA solar position, ±1–2 minutes of references).
/// Everything runs on this device; no network, no location permission.
enum PrayerEngine {

    static let kaabaLatitude = 21.422487
    static let kaabaLongitude = 39.826206

    // MARK: - Public API

    static func times(
        on date: Date,
        latitude: Double,
        longitude: Double,
        timeZone: TimeZone,
        method: CalculationMethod,
        hanafiAsr: Bool
    ) -> PrayerTimes {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let year = comps.year ?? 2026
        let month = comps.month ?? 1
        let day = comps.day ?? 1
        let midnight = calendar.date(from: comps) ?? date
        let tzHours = Double(timeZone.secondsFromGMT(for: date)) / 3600.0

        let jDate = julianDay(year: year, month: month, day: day) - longitude / (15.0 * 24.0)

        func adjusted(_ hours: Double?) -> Double? {
            guard let hours else { return nil }
            return hours + tzHours - longitude / 15.0
        }

        let riseSetAngle = 0.833

        var fajr = adjusted(sunAngleTime(angle: method.fajrAngle, dayFraction: 5.0 / 24, jDate: jDate, latitude: latitude, beforeNoon: true))
        let sunrise = adjusted(sunAngleTime(angle: riseSetAngle, dayFraction: 6.0 / 24, jDate: jDate, latitude: latitude, beforeNoon: true))
        let dhuhr = adjusted(midDay(dayFraction: 12.0 / 24, jDate: jDate))
        let asr = adjusted(asrTime(factor: hanafiAsr ? 2 : 1, dayFraction: 13.0 / 24, jDate: jDate, latitude: latitude))
        let sunset = adjusted(sunAngleTime(angle: riseSetAngle, dayFraction: 18.0 / 24, jDate: jDate, latitude: latitude, beforeNoon: false))
        let maghrib = sunset
        var isha: Double?
        if let angle = method.ishaAngle {
            isha = adjusted(sunAngleTime(angle: angle, dayFraction: 18.0 / 24, jDate: jDate, latitude: latitude, beforeNoon: false))
        } else if let maghrib {
            isha = maghrib + method.ishaMinutesAfterMaghrib / 60.0
        }

        // High-latitude fallback: middle-of-the-night rule when the sun never
        // reaches the required depression angle.
        if let sunrise, let sunset {
            let night = 24.0 - (sunset - sunrise)
            if fajr == nil { fajr = sunrise - night / 2.0 }
            if isha == nil { isha = sunset + night / 2.0 }
        }

        var result: [Prayer: Date] = [:]
        let pairs: [(Prayer, Double?)] = [
            (.fajr, fajr), (.sunrise, sunrise), (.dhuhr, dhuhr),
            (.asr, asr), (.maghrib, maghrib), (.isha, isha),
        ]
        for (prayer, hours) in pairs {
            guard let hours, hours.isFinite else { continue }
            result[prayer] = midnight.addingTimeInterval(hours * 3600.0)
        }
        return PrayerTimes(day: midnight, times: result, timeZone: timeZone)
    }

    /// Great-circle initial bearing from (lat, lon) to the Kaaba, degrees from true north.
    static func qiblaBearing(latitude: Double, longitude: Double) -> Double {
        let phi1 = radians(latitude)
        let phi2 = radians(kaabaLatitude)
        let deltaLambda = radians(kaabaLongitude - longitude)
        let y = sin(deltaLambda)
        let x = cos(phi1) * tan(phi2) - sin(phi1) * cos(deltaLambda)
        return normalizeDegrees(degrees(atan2(y, x)))
    }

    /// Great-circle distance to the Kaaba in kilometres (haversine).
    static func distanceToKaabaKm(latitude: Double, longitude: Double) -> Double {
        let r = 6371.0
        let dPhi = radians(kaabaLatitude - latitude)
        let dLambda = radians(kaabaLongitude - longitude)
        let a = sin(dPhi / 2) * sin(dPhi / 2)
            + cos(radians(latitude)) * cos(radians(kaabaLatitude)) * sin(dLambda / 2) * sin(dLambda / 2)
        return r * 2 * atan2(sqrt(a), sqrt(1 - a))
    }

    // MARK: - Solar geometry

    private static func julianDay(year: Int, month: Int, day: Int) -> Double {
        var y = year
        var m = month
        if m <= 2 {
            y -= 1
            m += 12
        }
        let a = floor(Double(y) / 100.0)
        let b = 2 - a + floor(a / 4.0)
        return floor(365.25 * Double(y + 4716)) + floor(30.6001 * Double(m + 1)) + Double(day) + b - 1524.5
    }

    /// Sun declination (degrees) and equation of time (hours) for a Julian date.
    private static func sunPosition(_ jd: Double) -> (declination: Double, equation: Double) {
        let d = jd - 2451545.0
        let g = normalizeDegrees(357.529 + 0.98560028 * d)
        let q = normalizeDegrees(280.459 + 0.98564736 * d)
        let l = normalizeDegrees(q + 1.915 * sin(radians(g)) + 0.020 * sin(radians(2 * g)))
        let e = 23.439 - 0.00000036 * d
        let declination = degrees(asin(sin(radians(e)) * sin(radians(l))))
        var rightAscension = degrees(atan2(cos(radians(e)) * sin(radians(l)), cos(radians(l)))) / 15.0
        rightAscension = fixHour(rightAscension)
        let equation = q / 15.0 - rightAscension
        return (declination, normalizedEquation(equation))
    }

    /// Keep the equation of time in a sane ±1h band after the fixHour wrap.
    private static func normalizedEquation(_ value: Double) -> Double {
        var v = value
        while v > 12 { v -= 24 }
        while v < -12 { v += 24 }
        return v
    }

    private static func midDay(dayFraction: Double, jDate: Double) -> Double {
        let eqt = sunPosition(jDate + dayFraction).equation
        return fixHour(12 - eqt)
    }

    /// Hour at which the sun reaches `angle` degrees below the horizon.
    private static func sunAngleTime(
        angle: Double,
        dayFraction: Double,
        jDate: Double,
        latitude: Double,
        beforeNoon: Bool
    ) -> Double? {
        let pos = sunPosition(jDate + dayFraction)
        let noon = midDay(dayFraction: dayFraction, jDate: jDate)
        let term = (-sin(radians(angle)) - sin(radians(pos.declination)) * sin(radians(latitude)))
            / (cos(radians(pos.declination)) * cos(radians(latitude)))
        guard term >= -1, term <= 1 else { return nil } // polar day/night for this angle
        let t = degrees(acos(term)) / 15.0
        return noon + (beforeNoon ? -t : t)
    }

    /// Asr: shadow length equals `factor` × object height (1 standard, 2 Hanafi).
    private static func asrTime(factor: Double, dayFraction: Double, jDate: Double, latitude: Double) -> Double? {
        let pos = sunPosition(jDate + dayFraction)
        let angle = -degrees(atan(1.0 / (factor + tan(radians(abs(latitude - pos.declination))))))
        return sunAngleTime(angle: angle, dayFraction: dayFraction, jDate: jDate, latitude: latitude, beforeNoon: false)
    }

    // MARK: - Small helpers

    private static func radians(_ deg: Double) -> Double { deg * .pi / 180.0 }
    private static func degrees(_ rad: Double) -> Double { rad * 180.0 / .pi }

    private static func normalizeDegrees(_ value: Double) -> Double {
        var v = value.truncatingRemainder(dividingBy: 360.0)
        if v < 0 { v += 360.0 }
        return v
    }

    private static func fixHour(_ value: Double) -> Double {
        var v = value.truncatingRemainder(dividingBy: 24.0)
        if v < 0 { v += 24.0 }
        return v
    }
}
