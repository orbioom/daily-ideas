import Foundation

enum AstroMath {
    static func julianDate(from date: Date) -> Double {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        var Y = Double(comps.year ?? 2000)
        var M = Double(comps.month ?? 1)
        let h = Double(comps.hour ?? 0)
        let m = Double(comps.minute ?? 0)
        let s = Double(comps.second ?? 0)
        let D = Double(comps.day ?? 1) + (h + m / 60.0 + s / 3600.0) / 24.0
        if M <= 2 { Y -= 1; M += 12 }
        let A = floor(Y / 100.0)
        let B = 2.0 - A + floor(A / 4.0)
        return floor(365.25 * (Y + 4716.0)) + floor(30.6001 * (M + 1.0)) + D + B - 1524.5
    }

    static func gmstDeg(jd: Double) -> Double {
        let T = (jd - 2451545.0) / 36525.0
        var theta = 280.46061837 + 360.98564736629 * (jd - 2451545.0) + 0.000387933 * T * T - T * T * T / 38710000.0
        theta = theta.truncatingRemainder(dividingBy: 360.0)
        return theta < 0 ? theta + 360.0 : theta
    }

    static func lstDeg(gmst: Double, lonDeg: Double) -> Double {
        var l = (gmst + lonDeg).truncatingRemainder(dividingBy: 360.0)
        return l < 0 ? l + 360.0 : l
    }

    static func altAz(raDeg: Double, decDeg: Double, lstDeg: Double, latDeg: Double) -> (alt: Double, az: Double) {
        var H = (lstDeg - raDeg).truncatingRemainder(dividingBy: 360.0)
        if H < 0 { H += 360.0 }
        let hr = H * .pi / 180.0
        let dr = decDeg * .pi / 180.0
        let lr = latDeg * .pi / 180.0
        let sinAlt = sin(dr) * sin(lr) + cos(dr) * cos(lr) * cos(hr)
        let altR = asin(max(-1.0, min(1.0, sinAlt)))
        let cosAlt = cos(altR)
        let cosAz: Double
        if abs(cosAlt) < 1e-10 {
            cosAz = 0.0
        } else {
            cosAz = (sin(dr) - sinAlt * sin(lr)) / (cosAlt * cos(lr))
        }
        var az = acos(max(-1.0, min(1.0, cosAz))) * 180.0 / .pi
        if sin(hr) > 0 { az = 360.0 - az }
        return (altR * 180.0 / .pi, az)
    }

    // Low-precision Sun RA/Dec (degrees), accurate to ~1°
    static func sunPosition(jd: Double) -> (raDeg: Double, decDeg: Double) {
        let n = jd - 2451545.0
        let L = mod360(280.46 + 0.9856474 * n)
        let gRad = mod360(357.528 + 0.9856003 * n) * .pi / 180.0
        let lambdaDeg = L + 1.915 * sin(gRad) + 0.020 * sin(2 * gRad)
        let lambdaRad = lambdaDeg * .pi / 180.0
        let epsRad = 23.439 * .pi / 180.0
        let ra = atan2(cos(epsRad) * sin(lambdaRad), cos(lambdaRad)) * 180.0 / .pi
        let dec = asin(sin(epsRad) * sin(lambdaRad)) * 180.0 / .pi
        return (mod360(ra), dec)
    }

    // Low-precision Moon RA/Dec (degrees), accurate to ~5°
    static func moonPosition(jd: Double) -> (raDeg: Double, decDeg: Double) {
        let d = jd - 2451545.0
        let L = mod360(218.316 + 13.176396 * d)
        let M = mod360(134.963 + 13.064993 * d) * .pi / 180.0
        let F = mod360(93.272 + 13.229350 * d) * .pi / 180.0
        let lambdaRad = (L + 6.289 * sin(M)) * .pi / 180.0
        let betaRad = (5.128 * sin(F)) * .pi / 180.0
        let epsRad = 23.439 * .pi / 180.0
        let ra = atan2(sin(lambdaRad) * cos(epsRad) - tan(betaRad) * sin(epsRad), cos(lambdaRad)) * 180.0 / .pi
        let dec = asin(sin(betaRad) * cos(epsRad) + cos(betaRad) * sin(epsRad) * sin(lambdaRad)) * 180.0 / .pi
        return (mod360(ra), dec)
    }

    // Moon phase 0=new, 0.5=full, 1=new
    static func moonPhase(jd: Double) -> Double {
        let d = jd - 2451545.0
        let phase = d / 29.53058867
        return phase - floor(phase)
    }

    // Moon age in days
    static func moonAge(jd: Double) -> Double {
        return moonPhase(jd: jd) * 29.53058867
    }

    // Simplified planet RA/Dec using mean orbital elements
    static func planetPosition(planet: PlanetName, jd: Double) -> (raDeg: Double, decDeg: Double) {
        let d = jd - 2451545.0
        let epsRad = 23.439 * .pi / 180.0
        let lambdaRad: Double
        switch planet {
        case .venus:
            let M = mod360(212.803 + 1.6021170 * d) * .pi / 180.0
            let L = mod360(181.979 + 1.6021302 * d)
            lambdaRad = (L + 0.7758 * sin(M) + 0.0050 * sin(2*M)) * .pi / 180.0
        case .mars:
            let M = mod360(19.374 + 0.5240632 * d) * .pi / 180.0
            let L = mod360(355.433 + 0.5240208 * d)
            lambdaRad = (L + 10.691 * sin(M) + 0.623 * sin(2*M)) * .pi / 180.0
        case .jupiter:
            let M = mod360(20.020 + 0.0830948 * d) * .pi / 180.0
            let L = mod360(34.396 + 0.0830853 * d)
            lambdaRad = (L + 5.555 * sin(M) + 0.168 * sin(2*M)) * .pi / 180.0
        case .saturn:
            let M = mod360(317.020 + 0.0334782 * d) * .pi / 180.0
            let L = mod360(50.077 + 0.0334718 * d)
            lambdaRad = (L + 6.393 * sin(M) + 0.226 * sin(2*M)) * .pi / 180.0
        }
        let ra = atan2(sin(lambdaRad) * cos(epsRad), cos(lambdaRad)) * 180.0 / .pi
        let dec = asin(sin(epsRad) * sin(lambdaRad)) * 180.0 / .pi
        return (mod360(ra), dec)
    }

    // Rise/set time approximation for an object (returns hours UT or nil if circumpolar/never-rises)
    static func riseSetHours(raDeg: Double, decDeg: Double, latDeg: Double, lonDeg: Double, jd0: Double) -> (rise: Double?, set: Double?) {
        let dr = decDeg * .pi / 180.0
        let lr = latDeg * .pi / 180.0
        let cosH = -tan(lr) * tan(dr)
        guard abs(cosH) <= 1.0 else { return (nil, nil) }
        let H0 = acos(cosH) * 180.0 / .pi
        let transit = mod24(raDeg / 15.0 - (gmstDeg(jd: jd0) + lonDeg) / 15.0)
        let rise = mod24(transit - H0 / 15.0)
        let set = mod24(transit + H0 / 15.0)
        return (rise, set)
    }

    private static func mod360(_ x: Double) -> Double {
        var r = x.truncatingRemainder(dividingBy: 360.0)
        return r < 0 ? r + 360.0 : r
    }

    private static func mod24(_ x: Double) -> Double {
        var r = x.truncatingRemainder(dividingBy: 24.0)
        return r < 0 ? r + 24.0 : r
    }
}
