import Foundation

/// The Solar-System bodies Lodestar computes.
enum SolarBody: String, CaseIterable, Identifiable {
    case sun = "Sun"
    case moon = "Moon"
    case mercury = "Mercury"
    case venus = "Venus"
    case mars = "Mars"
    case jupiter = "Jupiter"
    case saturn = "Saturn"
    case uranus = "Uranus"
    case neptune = "Neptune"

    var id: String { rawValue }

    var displayName: String { rawValue }

    /// Approximate visual magnitude used for "best objects" ranking and labels.
    /// (Planets vary; these are representative bright-apparition values.)
    var nominalMagnitude: Double {
        switch self {
        case .sun: return -26.7
        case .moon: return -12.7
        case .mercury: return 0.0
        case .venus: return -4.2
        case .mars: return 0.7
        case .jupiter: return -2.2
        case .saturn: return 0.5
        case .uranus: return 5.7
        case .neptune: return 7.8
        }
    }

    /// Whether the body is gated behind Pro on the chart's "outer planets".
    var isOuterIce: Bool { self == .uranus || self == .neptune }
}

/// Keplerian orbital elements (Schlyter) as linear functions of the day number `d`.
private struct OrbitalElements {
    var N: Double   // longitude of ascending node
    var i: Double   // inclination
    var w: Double   // argument of perihelion
    var a: Double   // semi-major axis
    var e: Double   // eccentricity
    var M: Double   // mean anomaly

    /// Evaluate the elements for day number d (rates given per day).
    static func evaluate(_ body: SolarBody, d: Double) -> OrbitalElements {
        func e(_ base: Double, _ rate: Double) -> Double { base + rate * d }
        switch body {
        case .sun, .moon:
            // Sun handled specially; never reached for elements path.
            return OrbitalElements(N: 0, i: 0, w: e(282.9404, 4.70935e-5),
                                   a: 1.0, e: e(0.016709, -1.151e-9),
                                   M: e(356.0470, 0.9856002585))
        case .mercury:
            return OrbitalElements(N: e(48.3313, 3.24587e-5), i: e(7.0047, 5.00e-8),
                                   w: e(29.1241, 1.01444e-5), a: 0.387098,
                                   e: e(0.205635, 5.59e-10), M: e(168.6562, 4.0923344368))
        case .venus:
            return OrbitalElements(N: e(76.6799, 2.46590e-5), i: e(3.3946, 2.75e-8),
                                   w: e(54.8910, 1.38374e-5), a: 0.723330,
                                   e: e(0.006773, -1.302e-9), M: e(48.0052, 1.6021302244))
        case .mars:
            return OrbitalElements(N: e(49.5574, 2.11081e-5), i: e(1.8497, -1.78e-8),
                                   w: e(286.5016, 2.92961e-5), a: 1.523688,
                                   e: e(0.093405, 2.516e-9), M: e(18.6021, 0.5240207766))
        case .jupiter:
            return OrbitalElements(N: e(100.4542, 2.76854e-5), i: e(1.3030, -1.557e-7),
                                   w: e(273.8777, 1.64505e-5), a: 5.20256,
                                   e: e(0.048498, 4.469e-9), M: e(19.8950, 0.0830853001))
        case .saturn:
            return OrbitalElements(N: e(113.6634, 2.38980e-5), i: e(2.4886, -1.081e-7),
                                   w: e(339.3939, 2.97661e-5), a: 9.55475,
                                   e: e(0.055546, -9.499e-9), M: e(316.9670, 0.0334442282))
        case .uranus:
            return OrbitalElements(N: e(74.0005, 1.3978e-5), i: e(0.7733, 1.9e-8),
                                   w: e(96.6612, 3.0565e-5), a: e(19.18171, -1.55e-8),
                                   e: e(0.047318, 7.45e-9), M: e(142.5905, 0.011725806))
        case .neptune:
            return OrbitalElements(N: e(131.7806, 3.0173e-5), i: e(1.7700, -2.55e-7),
                                   w: e(272.8461, -6.027e-6), a: e(30.05826, 3.313e-8),
                                   e: e(0.008606, 2.15e-9), M: e(260.2471, 0.005995147))
        }
    }
}

/// Computes geocentric positions of Solar-System bodies for a given instant.
/// Implementation follows Paul Schlyter's "How to compute planetary positions".
enum Ephemeris {

    /// Solve Kepler's equation for the eccentric anomaly E (degrees), guarded & iterative.
    private static func eccentricAnomaly(meanAnomalyDeg M: Double, eccentricity e: Double) -> Double {
        let mNorm = AstroMath.normalize360(M)
        var E = mNorm + AstroMath.deg(e) * AstroMath.sind(mNorm) * (1.0 + e * AstroMath.cosd(mNorm))
        // Newton iteration; e < 1 for all our bodies, so the denominator stays > 0.
        for _ in 0..<12 {
            let denom = 1.0 - e * AstroMath.cosd(E)
            guard abs(denom) > 1e-9 else { break }
            let dE = (E - AstroMath.deg(e) * AstroMath.sind(E) - mNorm) / denom
            E -= dE
            if abs(dE) < 1e-7 { break }
        }
        return E
    }

    /// Geocentric ecliptic coordinates of the Sun for the instant.
    private static func sunEcliptic(d: Double) -> (ecl: EclipticCoord, lonSun: Double, distance: Double) {
        let w = 282.9404 + 4.70935e-5 * d
        let e = 0.016709 - 1.151e-9 * d
        let M = AstroMath.normalize360(356.0470 + 0.9856002585 * d)

        let E = M + AstroMath.deg(e) * AstroMath.sind(M) * (1.0 + e * AstroMath.cosd(M))
        let xv = AstroMath.cosd(E) - e
        let yv = sqrt(max(0, 1.0 - e * e)) * AstroMath.sind(E)
        let r = sqrt(xv * xv + yv * yv)
        let v = AstroMath.atan2d(yv, xv)
        let lonSun = AstroMath.normalize360(v + w)
        return (EclipticCoord(longitude: lonSun, latitude: 0, distance: r), lonSun, r)
    }

    /// Geocentric equatorial coordinates of any body for the instant.
    static func equatorial(for body: SolarBody, at date: Date) -> EquatorialCoord {
        let d = JulianDate.dayNumber(from: date)
        let ecl = JulianDate.obliquity(from: date)
        let position = geocentricEcliptic(for: body, d: d)
        return CoordTransform.eclipticToEquatorial(position, obliquity: ecl)
    }

    /// Geocentric ecliptic coordinates of a body (degrees / AU-ish distance).
    static func geocentricEcliptic(for body: SolarBody, d: Double) -> EclipticCoord {
        switch body {
        case .sun:
            return sunEcliptic(d: d).ecl
        case .moon:
            return moonEcliptic(d: d)
        default:
            return planetEcliptic(body, d: d)
        }
    }

    /// Heliocentric → geocentric ecliptic position of a planet (with Sun added).
    private static func planetEcliptic(_ body: SolarBody, d: Double) -> EclipticCoord {
        let el = OrbitalElements.evaluate(body, d: d)
        let E = eccentricAnomaly(meanAnomalyDeg: el.M, eccentricity: el.e)

        // Position in orbital plane.
        let xv = el.a * (AstroMath.cosd(E) - el.e)
        let yv = el.a * sqrt(max(0, 1.0 - el.e * el.e)) * AstroMath.sind(E)
        let r = sqrt(xv * xv + yv * yv)
        let v = AstroMath.atan2d(yv, xv)

        // Heliocentric ecliptic rectangular coordinates.
        let vw = v + el.w
        let xh = r * (AstroMath.cosd(el.N) * AstroMath.cosd(vw)
                      - AstroMath.sind(el.N) * AstroMath.sind(vw) * AstroMath.cosd(el.i))
        let yh = r * (AstroMath.sind(el.N) * AstroMath.cosd(vw)
                      + AstroMath.cosd(el.N) * AstroMath.sind(vw) * AstroMath.cosd(el.i))
        let zh = r * (AstroMath.sind(vw) * AstroMath.sind(el.i))

        // Add the Sun's geocentric position (Earth's heliocentric is -Sun).
        let sun = sunEcliptic(d: d)
        let xs = sun.distance * AstroMath.cosd(sun.lonSun)
        let ys = sun.distance * AstroMath.sind(sun.lonSun)

        let xg = xh + xs
        let yg = yh + ys
        let zg = zh

        let lon = AstroMath.atan2d(yg, xg)
        let lat = AstroMath.asind(zg / max(1e-9, sqrt(xg * xg + yg * yg + zg * zg)))
        let dist = sqrt(xg * xg + yg * yg + zg * zg)
        return EclipticCoord(longitude: lon, latitude: lat, distance: dist)
    }

    /// Geocentric ecliptic position of the Moon, including the main perturbation terms.
    private static func moonEcliptic(d: Double) -> EclipticCoord {
        let N = AstroMath.normalize360(125.1228 - 0.0529538083 * d)
        let i = 5.1454
        let w = AstroMath.normalize360(318.0634 + 0.1643573223 * d)
        let a = 60.2666 // Earth radii
        let e = 0.054900
        let M = AstroMath.normalize360(115.3654 + 13.0649929509 * d)

        let E0 = M + AstroMath.deg(e) * AstroMath.sind(M) * (1.0 + e * AstroMath.cosd(M))
        var E = E0
        for _ in 0..<8 {
            let denom = 1.0 - e * AstroMath.cosd(E)
            guard abs(denom) > 1e-9 else { break }
            let dE = (E - AstroMath.deg(e) * AstroMath.sind(E) - M) / denom
            E -= dE
            if abs(dE) < 1e-6 { break }
        }

        let xv = a * (AstroMath.cosd(E) - e)
        let yv = a * sqrt(max(0, 1.0 - e * e)) * AstroMath.sind(E)
        let r = sqrt(xv * xv + yv * yv)
        let v = AstroMath.atan2d(yv, xv)

        let vw = v + w
        let xh = r * (AstroMath.cosd(N) * AstroMath.cosd(vw)
                      - AstroMath.sind(N) * AstroMath.sind(vw) * AstroMath.cosd(i))
        let yh = r * (AstroMath.sind(N) * AstroMath.cosd(vw)
                      + AstroMath.cosd(N) * AstroMath.sind(vw) * AstroMath.cosd(i))
        let zh = r * (AstroMath.sind(vw) * AstroMath.sind(i))

        var lon = AstroMath.atan2d(yh, xh)
        var lat = AstroMath.asind(zh / max(1e-9, sqrt(xh * xh + yh * yh + zh * zh)))

        // Perturbations: need Sun's mean longitude / anomaly and the Moon's.
        let sun = sunEcliptic(d: d)
        let Ms = AstroMath.normalize360(356.0470 + 0.9856002585 * d) // Sun mean anomaly
        let Ls = sun.lonSun                                          // Sun mean longitude (≈ true here)
        let Mm = M                                                   // Moon mean anomaly
        let Lm = AstroMath.normalize360(N + w + M)                   // Moon mean longitude
        let D = AstroMath.normalize360(Lm - Ls)                      // mean elongation
        let F = AstroMath.normalize360(Lm - N)                       // argument of latitude

        // Longitude perturbations (degrees).
        var dLon = 0.0
        dLon += -1.274 * AstroMath.sind(Mm - 2 * D)   // Evection
        dLon += 0.658 * AstroMath.sind(2 * D)         // Variation
        dLon += -0.186 * AstroMath.sind(Ms)           // Yearly equation
        dLon += -0.059 * AstroMath.sind(2 * Mm - 2 * D)
        dLon += -0.057 * AstroMath.sind(Mm - 2 * D + Ms)
        dLon += 0.053 * AstroMath.sind(Mm + 2 * D)
        dLon += 0.046 * AstroMath.sind(2 * D - Ms)
        dLon += 0.041 * AstroMath.sind(Mm - Ms)
        dLon += -0.035 * AstroMath.sind(D)            // Parallactic equation
        dLon += -0.031 * AstroMath.sind(Mm + Ms)
        dLon += -0.015 * AstroMath.sind(2 * F - 2 * D)
        dLon += 0.011 * AstroMath.sind(Mm - 4 * D)
        lon = AstroMath.normalize360(lon + dLon)

        // Latitude perturbations (degrees).
        var dLat = 0.0
        dLat += -0.173 * AstroMath.sind(F - 2 * D)
        dLat += -0.055 * AstroMath.sind(Mm - F - 2 * D)
        dLat += -0.046 * AstroMath.sind(Mm + F - 2 * D)
        dLat += 0.033 * AstroMath.sind(F + 2 * D)
        dLat += 0.017 * AstroMath.sind(2 * Mm + F)
        lat = lat + dLat

        return EclipticCoord(longitude: lon, latitude: lat, distance: r)
    }

    /// Geocentric ecliptic longitude of the Sun (degrees) — used for Moon phase.
    static func sunLongitude(at date: Date) -> Double {
        sunEcliptic(d: JulianDate.dayNumber(from: date)).lonSun
    }

    /// Geocentric ecliptic longitude of the Moon (degrees) — used for Moon phase.
    static func moonLongitude(at date: Date) -> Double {
        moonEcliptic(d: JulianDate.dayNumber(from: date)).longitude
    }
}
