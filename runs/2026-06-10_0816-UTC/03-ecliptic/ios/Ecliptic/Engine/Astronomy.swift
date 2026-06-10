import Foundation

/// On-device ephemeris, accurate to a few arcminutes for the classical
/// planets across 1800–2050 — more than enough to place a chart to the
/// degree. Sun from Meeus' solar theory, Moon from the principal ELP terms,
/// planets from the JPL approximate Keplerian elements; Earth via the
/// Earth–Moon barycenter. Pure functions, degrees in/out.
enum Astronomy {

    // MARK: Time

    static func julianDay(_ date: Date) -> Double {
        2440587.5 + date.timeIntervalSince1970 / 86400.0
    }

    static func centuries(_ jd: Double) -> Double {
        (jd - 2451545.0) / 36525.0
    }

    // MARK: Degree helpers

    static func norm(_ deg: Double) -> Double {
        var d = deg.truncatingRemainder(dividingBy: 360)
        if d < 0 { d += 360 }
        return d
    }

    static func sinD(_ d: Double) -> Double { sin(d * .pi / 180) }
    static func cosD(_ d: Double) -> Double { cos(d * .pi / 180) }
    static func tanD(_ d: Double) -> Double { tan(d * .pi / 180) }
    static func atan2D(_ y: Double, _ x: Double) -> Double { atan2(y, x) * 180 / .pi }

    // MARK: Sun (Meeus ch. 25, geocentric apparent within ~0.01°)

    static func sunLongitude(jd: Double) -> Double {
        let T = centuries(jd)
        let L0 = 280.46646 + 36000.76983 * T + 0.0003032 * T * T
        let M = 357.52911 + 35999.05029 * T - 0.0001537 * T * T
        let C = (1.914602 - 0.004817 * T - 0.000014 * T * T) * sinD(M)
            + (0.019993 - 0.000101 * T) * sinD(2 * M)
            + 0.000289 * sinD(3 * M)
        return norm(L0 + C)
    }

    // MARK: Moon (principal periodic terms, ~0.05° accuracy)

    static func moonLongitude(jd: Double) -> Double {
        let T = centuries(jd)
        let Lp = 218.3164477 + 481267.88123421 * T - 0.0015786 * T * T
        let D  = 297.8501921 + 445267.1114034 * T - 0.0018819 * T * T
        let M  = 357.5291092 + 35999.0502909 * T - 0.0001536 * T * T
        let Mp = 134.9633964 + 477198.8675055 * T + 0.0087414 * T * T
        let F  = 93.2720950 + 483202.0175233 * T - 0.0036539 * T * T

        var s = 6.288774 * sinD(Mp)
        s += 1.274027 * sinD(2 * D - Mp)
        s += 0.658314 * sinD(2 * D)
        s += 0.213618 * sinD(2 * Mp)
        s -= 0.185116 * sinD(M)
        s -= 0.114332 * sinD(2 * F)
        s += 0.058793 * sinD(2 * D - 2 * Mp)
        s += 0.057066 * sinD(2 * D - M - Mp)
        s += 0.053322 * sinD(2 * D + Mp)
        s += 0.045758 * sinD(2 * D - M)
        s -= 0.040923 * sinD(M - Mp)
        s -= 0.034720 * sinD(D)
        s -= 0.030383 * sinD(M + Mp)
        return norm(Lp + s)
    }

    // MARK: Planets (JPL approximate elements, valid 1800–2050)

    struct Elements {
        let a: Double, aDot: Double          // semi-major axis (AU, AU/cy)
        let e: Double, eDot: Double          // eccentricity
        let i: Double, iDot: Double          // inclination (deg)
        let L: Double, LDot: Double          // mean longitude (deg)
        let varpi: Double, varpiDot: Double  // longitude of perihelion (deg)
        let Omega: Double, OmegaDot: Double  // longitude of ascending node (deg)
    }

    enum Body: CaseIterable {
        case mercury, venus, earthMoonBary, mars, jupiter, saturn, uranus, neptune, pluto
    }

    static func elements(for body: Body) -> Elements {
        switch body {
        case .mercury:
            return Elements(a: 0.38709927, aDot: 0.00000037, e: 0.20563593, eDot: 0.00001906,
                            i: 7.00497902, iDot: -0.00594749, L: 252.25032350, LDot: 149472.67411175,
                            varpi: 77.45779628, varpiDot: 0.16047689, Omega: 48.33076593, OmegaDot: -0.12534081)
        case .venus:
            return Elements(a: 0.72333566, aDot: 0.00000390, e: 0.00677672, eDot: -0.00004107,
                            i: 3.39467605, iDot: -0.00078890, L: 181.97909950, LDot: 58517.81538729,
                            varpi: 131.60246718, varpiDot: 0.00268329, Omega: 76.67984255, OmegaDot: -0.27769418)
        case .earthMoonBary:
            return Elements(a: 1.00000261, aDot: 0.00000562, e: 0.01671123, eDot: -0.00004392,
                            i: -0.00001531, iDot: -0.01294668, L: 100.46457166, LDot: 35999.37244981,
                            varpi: 102.93768193, varpiDot: 0.32327364, Omega: 0.0, OmegaDot: 0.0)
        case .mars:
            return Elements(a: 1.52371034, aDot: 0.00001847, e: 0.09339410, eDot: 0.00007882,
                            i: 1.84969142, iDot: -0.00813131, L: -4.55343205, LDot: 19140.30268499,
                            varpi: -23.94362959, varpiDot: 0.44441088, Omega: 49.55953891, OmegaDot: -0.29257343)
        case .jupiter:
            return Elements(a: 5.20288700, aDot: -0.00011607, e: 0.04838624, eDot: -0.00013253,
                            i: 1.30439695, iDot: -0.00183714, L: 34.39644051, LDot: 3034.74612775,
                            varpi: 14.72847983, varpiDot: 0.21252668, Omega: 100.47390909, OmegaDot: 0.20469106)
        case .saturn:
            return Elements(a: 9.53667594, aDot: -0.00125060, e: 0.05386179, eDot: -0.00050991,
                            i: 2.48599187, iDot: 0.00193609, L: 49.95424423, LDot: 1222.49362201,
                            varpi: 92.59887831, varpiDot: -0.41897216, Omega: 113.66242448, OmegaDot: -0.28867794)
        case .uranus:
            return Elements(a: 19.18916464, aDot: -0.00196176, e: 0.04725744, eDot: -0.00004397,
                            i: 0.77263783, iDot: -0.00242939, L: 313.23810451, LDot: 428.48202785,
                            varpi: 170.95427630, varpiDot: 0.40805281, Omega: 74.01692503, OmegaDot: 0.04240589)
        case .neptune:
            return Elements(a: 30.06992276, aDot: 0.00026291, e: 0.00859048, eDot: 0.00005105,
                            i: 1.77004347, iDot: 0.00035372, L: -55.12002969, LDot: 218.45945325,
                            varpi: 44.96476227, varpiDot: -0.32241464, Omega: 131.78422574, OmegaDot: -0.00508664)
        case .pluto:
            return Elements(a: 39.48211675, aDot: -0.00031596, e: 0.24882730, eDot: 0.00005170,
                            i: 17.14001206, iDot: 0.00004818, L: 238.92903833, LDot: 145.20780515,
                            varpi: 224.06891629, varpiDot: -0.04062942, Omega: 110.30393684, OmegaDot: -0.01183482)
        }
    }

    /// Heliocentric ecliptic rectangular coordinates (AU) at T centuries.
    static func heliocentric(_ body: Body, T: Double) -> (x: Double, y: Double, z: Double) {
        let el = elements(for: body)
        let a = el.a + el.aDot * T
        let e = el.e + el.eDot * T
        let i = el.i + el.iDot * T
        let L = el.L + el.LDot * T
        let varpi = el.varpi + el.varpiDot * T
        let Omega = el.Omega + el.OmegaDot * T

        let omega = varpi - Omega
        var M = norm(L - varpi)
        if M > 180 { M -= 360 }   // -180...180 for the solver

        // Kepler's equation, Newton iteration in degrees.
        let eStar = 57.29577951308232 * e
        var E = M + eStar * sinD(M)
        for _ in 0..<12 {
            let dM = M - (E - eStar * sinD(E))
            let dE = dM / (1 - e * cosD(E))
            E += dE
            if abs(dE) < 1e-8 { break }
        }

        let xP = a * (cosD(E) - e)
        let yP = a * (1 - e * e).squareRoot() * sinD(E)

        let cw = cosD(omega), sw = sinD(omega)
        let cO = cosD(Omega), sO = sinD(Omega)
        let ci = cosD(i), si = sinD(i)

        let x = (cw * cO - sw * sO * ci) * xP + (-sw * cO - cw * sO * ci) * yP
        let y = (cw * sO + sw * cO * ci) * xP + (-sw * sO + cw * cO * ci) * yP
        let z = (sw * si) * xP + (cw * si) * yP
        return (x, y, z)
    }

    /// Geocentric ecliptic longitude of a planet (deg).
    static func planetLongitude(_ body: Body, jd: Double) -> Double {
        let T = centuries(jd)
        let p = heliocentric(body, T: T)
        let e = heliocentric(.earthMoonBary, T: T)
        return norm(atan2D(p.y - e.y, p.x - e.x))
    }

    // MARK: Obliquity & sidereal time

    static func obliquity(jd: Double) -> Double {
        let T = centuries(jd)
        return 23.43929111 - 0.0130042 * T - 0.00000016 * T * T
    }

    /// Greenwich mean sidereal time as an angle (deg).
    static func gmst(jd: Double) -> Double {
        let T = centuries(jd)
        let g = 280.46061837 + 360.98564736629 * (jd - 2451545.0)
            + 0.000387933 * T * T - T * T * T / 38710000
        return norm(g)
    }

    /// Ecliptic longitude of the ascendant (deg).
    /// `longitude` is geographic, east-positive.
    static func ascendant(jd: Double, latitude: Double, longitude: Double) -> Double {
        let ramc = norm(gmst(jd: jd) + longitude)
        let eps = obliquity(jd: jd)
        let lat = min(max(latitude, -89.5), 89.5)
        let asc = atan2D(cosD(ramc), -(sinD(ramc) * cosD(eps) + tanD(lat) * sinD(eps)))
        return norm(asc)
    }

    /// Ecliptic longitude of the midheaven (deg).
    static func midheaven(jd: Double, longitude: Double) -> Double {
        let ramc = norm(gmst(jd: jd) + longitude)
        let eps = obliquity(jd: jd)
        return norm(atan2D(sinD(ramc), cosD(ramc) * cosD(eps)))
    }
}
