import Foundation

/// Sun position and event times using the NOAA Solar Calculator equations.
///
/// Reference: NOAA Earth System Research Laboratory, Global Monitoring Lab —
/// "Solar Calculation Details" (the spreadsheet method derived from
/// Jean Meeus, *Astronomical Algorithms*, 2nd ed., Willmann-Bell, 1998).
///
/// Longitude is east-positive degrees; `tz` is the UTC offset in hours
/// (east-positive). Times are returned as minutes from local midnight.
enum SolarCalculator {

    /// Julian day at 0h UTC of the calendar date.
    static func julianDay(_ date: Date) -> Double {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let c = cal.dateComponents([.year, .month, .day], from: date)
        var Y = c.year!, M = c.month!
        let D = Double(c.day!)
        if M <= 2 { Y -= 1; M += 12 }
        let A = floor(Double(Y) / 100.0)
        let B = 2 - A + floor(A / 4.0)
        return floor(365.25 * Double(Y + 4716)) + floor(30.6001 * Double(M + 1))
            + D + B - 1524.5
    }

    /// Core solar quantities for a given Julian century `t`.
    private static func solar(_ t: Double) -> (decl: Double, eqTime: Double) {
        let geomMeanLong = fmod(280.46646 + t * (36000.76983 + t * 0.0003032), 360.0)
        let geomMeanAnom = 357.52911 + t * (35999.05029 - 0.0001537 * t)
        let eccent = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)
        let m = geomMeanAnom * .pi / 180.0
        let sinEoC = sin(m) * (1.914602 - t * (0.004817 + 0.000014 * t))
            + sin(2 * m) * (0.019993 - 0.000101 * t)
            + sin(3 * m) * 0.000289
        let trueLong = geomMeanLong + sinEoC
        let appLong = trueLong - 0.00569 - 0.00478 * sin((125.04 - 1934.136 * t) * .pi / 180.0)
        let mObl = 23.0 + (26.0 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60.0) / 60.0
        let oblCorr = mObl + 0.00256 * cos((125.04 - 1934.136 * t) * .pi / 180.0)
        let declin = asin(sin(oblCorr * .pi / 180.0) * sin(appLong * .pi / 180.0)) * 180.0 / .pi
        let varY = pow(tan(oblCorr / 2.0 * .pi / 180.0), 2)
        let gml = geomMeanLong * .pi / 180.0
        let eqTime = 4.0 * (varY * sin(2 * gml) - 2 * eccent * sin(m)
            + 4 * eccent * varY * sin(m) * cos(2 * gml)
            - 0.5 * varY * varY * sin(4 * gml)
            - 1.25 * eccent * eccent * sin(2 * m)) * 180.0 / .pi
        return (declin, eqTime)
    }

    /// Minutes from local midnight at which the sun reaches `angle` (degrees
    /// above the horizon). Returns nil if it never reaches that angle today.
    static func eventMinutes(angle: Double, date: Date, lat: Double,
                             lon: Double, tz: Double, rising: Bool) -> Double? {
        let jNoon = julianDay(date) + 0.5 - tz / 24.0   // ~local solar noon in UT
        let t = (jNoon - 2451545.0) / 36525.0
        let s = solar(t)
        let latR = lat * .pi / 180.0
        let declR = s.decl * .pi / 180.0
        let zenith = (90.0 - angle) * .pi / 180.0
        let cosH = (cos(zenith) - sin(latR) * sin(declR)) / (cos(latR) * cos(declR))
        if cosH > 1.0 || cosH < -1.0 { return nil }
        let ha = acos(cosH) * 180.0 / .pi
        let solarNoon = 720.0 - 4.0 * lon - s.eqTime + tz * 60.0
        return rising ? solarNoon - 4.0 * ha : solarNoon + 4.0 * ha
    }

    /// Local-clock minutes of solar noon.
    static func solarNoonMinutes(date: Date, lon: Double, tz: Double) -> Double {
        let jNoon = julianDay(date) + 0.5 - tz / 24.0
        let t = (jNoon - 2451545.0) / 36525.0
        let s = solar(t)
        return 720.0 - 4.0 * lon - s.eqTime + tz * 60.0
    }

    /// Solar elevation (degrees above horizon) at an instant.
    static func elevation(date: Date, lat: Double, lon: Double, tz: Double) -> Double {
        let jNoon = julianDay(date) + 0.5 - tz / 24.0
        let t = (jNoon - 2451545.0) / 36525.0
        let s = solar(t)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: Int(tz * 3600)) ?? .current
        let c = cal.dateComponents([.hour, .minute, .second], from: date)
        let localMin = Double(c.hour!) * 60.0 + Double(c.minute!) + Double(c.second!) / 60.0
        var tst = fmod(localMin + s.eqTime + 4.0 * lon - 60.0 * tz, 1440.0)
        if tst < 0 { tst += 1440.0 }
        let ha = tst / 4.0 < 0 ? tst / 4.0 + 180.0 : tst / 4.0 - 180.0
        let latR = lat * .pi / 180.0, declR = s.decl * .pi / 180.0
        let haR = ha * .pi / 180.0
        let cosZ = sin(latR) * sin(declR) + cos(latR) * cos(declR) * cos(haR)
        return 90.0 - acos(max(-1.0, min(1.0, cosZ))) * 180.0 / .pi
    }
}
