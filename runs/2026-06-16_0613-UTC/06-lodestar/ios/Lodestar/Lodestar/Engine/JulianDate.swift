import Foundation

/// Julian Day / sidereal time utilities.
/// References use Paul Schlyter's day-number convention `d = JD - 2451543.5`,
/// which is exposed alongside the standard Julian Day.
enum JulianDate {
    /// Julian Day for a given instant (UTC).
    static func julianDay(from date: Date) -> Double {
        // Unix epoch 1970-01-01T00:00:00Z corresponds to JD 2440587.5.
        date.timeIntervalSince1970 / 86400.0 + 2440587.5
    }

    /// Schlyter's day number `d`, zero at 1999-12-31 00:00 UT (JD 2451543.5).
    static func dayNumber(from date: Date) -> Double {
        julianDay(from: date) - 2451543.5
    }

    /// Greenwich Mean Sidereal Time in degrees [0,360) for the instant.
    /// Uses the IAU 1982 expression with T in Julian centuries from J2000.0.
    static func gmstDegrees(from date: Date) -> Double {
        let jd = julianDay(from: date)
        let t = (jd - 2451545.0) / 36525.0
        var gmst = 280.46061837
            + 360.98564736629 * (jd - 2451545.0)
            + 0.000387933 * t * t
            - (t * t * t) / 38710000.0
        gmst = AstroMath.normalize360(gmst)
        return gmst
    }

    /// Local Mean Sidereal Time in degrees [0,360) for a longitude (east positive).
    static func lmstDegrees(from date: Date, longitudeEast: Double) -> Double {
        AstroMath.normalize360(gmstDegrees(from: date) + longitudeEast)
    }

    /// Local Mean Sidereal Time in hours [0,24).
    static func lmstHours(from date: Date, longitudeEast: Double) -> Double {
        lmstDegrees(from: date, longitudeEast: longitudeEast) / 15.0
    }

    /// Obliquity of the ecliptic in degrees for the instant (Schlyter's linear term in d).
    static func obliquity(from date: Date) -> Double {
        let d = dayNumber(from: date)
        return 23.4393 - 3.563e-7 * d
    }
}
