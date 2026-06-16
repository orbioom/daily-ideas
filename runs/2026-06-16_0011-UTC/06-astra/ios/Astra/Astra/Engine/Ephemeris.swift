import Foundation

// MARK: - Ephemeris
//
// Accurate, on-device planetary positions — the credibility piece.
//
// Method: Paul Schlyter's well-known public-domain algorithm
// "Computing planetary positions — a tutorial with worked examples"
// (https://stjarnhimlen.se/comp/ppcomp.html). It is a low-precision
// (heliocentric Keplerian two-body) method good to roughly ~1–2 arcminutes
// for the Sun and planets; the Moon is a little coarser here because we
// include only the principal perturbation terms (still well within ~1°,
// and typically much better). That is far more accurate than a chart needs,
// and unlike many consumer apps it is computed honestly rather than looked up
// from a coarse table or hard-coded "sun sign by date" guess.
//
// Pluto is not part of Schlyter's set; we use fixed modern mean orbital
// elements for it. It moves slowly enough that a two-body approximation keeps
// it in the correct sign and within a couple of degrees, which is all a
// natal/transit chart requires.
//
// EVERYTHING here is guarded: angles are normalized, asin/acos inputs are
// clamped to [-1, 1], and there is no unguarded division.

/// One body's geocentric ecliptic position.
struct BodyPosition: Identifiable {
    let planet: Planet
    /// Geocentric ecliptic longitude, 0..<360.
    let longitude: Double
    /// Distance from Earth in AU (Moon in Earth radii / 23455 ~ AU is not used; kept relative).
    let distance: Double
    let retrograde: Bool

    var id: Int { planet.rawValue }
    var sign: ZodiacSign { ZodiacSign.fromLongitude(longitude) }
    /// Degrees within the sign, 0..<30.
    var degreesInSign: Double {
        let n = AstroMath.norm360(longitude)
        return n.truncatingRemainder(dividingBy: 30)
    }
}

/// A fully computed chart for one moment + place.
struct Chart {
    let positions: [BodyPosition]
    /// Ascendant ecliptic longitude (nil when birth time is unknown).
    let ascendant: Double?
    /// Midheaven ecliptic longitude (nil when birth time is unknown).
    let midheaven: Double?

    func position(_ p: Planet) -> BodyPosition? {
        positions.first { $0.planet == p }
    }

    var ascendantSign: ZodiacSign? {
        guard let asc = ascendant else { return nil }
        return ZodiacSign.fromLongitude(asc)
    }

    var midheavenSign: ZodiacSign? {
        guard let mc = midheaven else { return nil }
        return ZodiacSign.fromLongitude(mc)
    }

    /// Whole-sign house for a body. Requires an Ascendant.
    func house(for p: Planet) -> House? {
        guard let ascSign = ascendantSign, let pos = position(p) else { return nil }
        return House.wholeSign(for: pos.sign, ascendant: ascSign)
    }
}

/// Small angle helpers — all guarded.
enum AstroMath {
    static let deg2rad = Double.pi / 180
    static let rad2deg = 180 / Double.pi

    /// Normalize degrees to 0..<360.
    static func norm360(_ x: Double) -> Double {
        let r = x.truncatingRemainder(dividingBy: 360)
        return r < 0 ? r + 360 : r
    }

    /// Normalize degrees to -180...180.
    static func norm180(_ x: Double) -> Double {
        var v = norm360(x)
        if v > 180 { v -= 360 }
        return v
    }

    static func sind(_ d: Double) -> Double { sin(d * deg2rad) }
    static func cosd(_ d: Double) -> Double { cos(d * deg2rad) }
    static func tand(_ d: Double) -> Double { tan(d * deg2rad) }

    /// atan2 returning degrees, normalized 0..<360.
    static func atan2d(_ y: Double, _ x: Double) -> Double {
        norm360(atan2(y, x) * rad2deg)
    }

    /// asin in degrees with the input clamped to [-1, 1].
    static func asind(_ x: Double) -> Double {
        asin(min(max(x, -1), 1)) * rad2deg
    }

    /// Smallest separation between two longitudes, 0...180.
    static func separation(_ a: Double, _ b: Double) -> Double {
        let d = abs(norm360(a) - norm360(b))
        return d > 180 ? 360 - d : d
    }
}

enum Ephemeris {

    /// Day number `d` for a calendar date at a given UT (hours, may be fractional).
    /// Uses Schlyter's integer-division formula; the +UT/24 term is the only Double part.
    static func dayNumber(year: Int, month: Int, day: Int, ut: Double) -> Double {
        let Y = year, M = month, D = day
        let term = 367 * Y
            - (7 * (Y + ((M + 9) / 12))) / 4
            + (275 * M) / 9
            + D
            - 730530
        return Double(term) + ut / 24.0
    }

    /// Day number for an absolute UTC `Date`.
    static func dayNumber(from utcDate: Date) -> Double {
        var cal = Calendar(identifier: .gregorian)
        if let utc = TimeZone(identifier: "UTC") { cal.timeZone = utc }
        let c = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: utcDate)
        let year = c.year ?? 2000
        let month = c.month ?? 1
        let day = c.day ?? 1
        let ut = Double(c.hour ?? 0) + Double(c.minute ?? 0) / 60 + Double(c.second ?? 0) / 3600
        return dayNumber(year: year, month: month, day: day, ut: ut)
    }

    /// Obliquity of the ecliptic in degrees.
    static func obliquity(_ d: Double) -> Double {
        23.4393 - 3.563e-7 * d
    }

    // MARK: Orbital elements

    /// Schlyter's orbital elements for one body at day `d`. Angles in degrees.
    private struct Elements {
        var N: Double   // longitude of ascending node
        var i: Double   // inclination to the ecliptic
        var w: Double   // argument of perihelion
        var a: Double   // semi-major axis (AU; Moon in Earth radii)
        var e: Double   // eccentricity
        var M: Double   // mean anomaly
    }

    private static func elements(for planet: Planet, d: Double) -> Elements {
        switch planet {
        case .sun:
            return Elements(N: 0, i: 0,
                            w: 282.9404 + 4.70935e-5 * d,
                            a: 1.0,
                            e: 0.016709 - 1.151e-9 * d,
                            M: 356.0470 + 0.9856002585 * d)
        case .moon:
            return Elements(N: 125.1228 - 0.0529538083 * d,
                            i: 5.1454,
                            w: 318.0634 + 0.1643573223 * d,
                            a: 60.2666,
                            e: 0.054900,
                            M: 115.3654 + 13.0649929509 * d)
        case .mercury:
            return Elements(N: 48.3313 + 3.24587e-5 * d,
                            i: 7.0047 + 5.00e-8 * d,
                            w: 29.1241 + 1.01444e-5 * d,
                            a: 0.387098,
                            e: 0.205635 + 5.59e-10 * d,
                            M: 168.6562 + 4.0923344368 * d)
        case .venus:
            return Elements(N: 76.6799 + 2.46590e-5 * d,
                            i: 3.3946 + 2.75e-8 * d,
                            w: 54.8910 + 1.38374e-5 * d,
                            a: 0.723330,
                            e: 0.006773 - 1.302e-9 * d,
                            M: 48.0052 + 1.6021302244 * d)
        case .mars:
            return Elements(N: 49.5574 + 2.11081e-5 * d,
                            i: 1.8497 - 1.78e-8 * d,
                            w: 286.5016 + 2.92961e-5 * d,
                            a: 1.523688,
                            e: 0.093405 + 2.516e-9 * d,
                            M: 18.6021 + 0.5240207766 * d)
        case .jupiter:
            return Elements(N: 100.4542 + 2.76854e-5 * d,
                            i: 1.3030 - 1.557e-7 * d,
                            w: 273.8777 + 1.64505e-5 * d,
                            a: 5.20256,
                            e: 0.048498 + 4.469e-9 * d,
                            M: 19.8950 + 0.0830853001 * d)
        case .saturn:
            return Elements(N: 113.6634 + 2.38980e-5 * d,
                            i: 2.4886 - 1.081e-7 * d,
                            w: 339.3939 + 2.97661e-5 * d,
                            a: 9.55475,
                            e: 0.055546 - 9.499e-9 * d,
                            M: 316.9670 + 0.0334442282 * d)
        case .uranus:
            return Elements(N: 74.0005 + 1.3978e-5 * d,
                            i: 0.7733 + 1.9e-8 * d,
                            w: 96.6612 + 3.0565e-5 * d,
                            a: 19.18171 - 1.55e-8 * d,
                            e: 0.047318 + 7.45e-9 * d,
                            M: 142.5905 + 0.011725806 * d)
        case .neptune:
            return Elements(N: 131.7806 + 3.0173e-5 * d,
                            i: 1.7700 - 2.55e-7 * d,
                            w: 272.8461 - 6.027e-6 * d,
                            a: 30.05826 + 3.313e-8 * d,
                            e: 0.008606 + 2.15e-9 * d,
                            M: 260.2471 + 0.005995147 * d)
        case .pluto:
            // Modern mean elements at J2000, with mean-motion advance. Two-body
            // approximation; adequate to keep Pluto in the right sign for a chart.
            let centuries = (d - 0.0) / 36525.0
            return Elements(N: 110.30347,
                            i: 17.14175,
                            w: 113.76329,
                            a: 39.48168677,
                            e: 0.24880766,
                            M: AstroMath.norm360(14.86012204 + 0.003979301 * d + 0.0 * centuries))
        }
    }

    /// Solve Kepler's equation for eccentric anomaly E (degrees), iterating for high-e bodies.
    private static func eccentricAnomaly(M: Double, e: Double) -> Double {
        let Mn = AstroMath.norm360(M)
        let Mrad = Mn * AstroMath.deg2rad
        // First approximation.
        var E = Mn + (AstroMath.rad2deg) * e * sin(Mrad) * (1 + e * cos(Mrad))
        // Iterate Newton-Raphson a few times (needed for the Moon and other high-e orbits).
        for _ in 0..<8 {
            let Erad = E * AstroMath.deg2rad
            let dE = (E - AstroMath.rad2deg * e * sin(Erad) - Mn) /
                     (1 - e * cos(Erad))
            E -= dE
            if abs(dE) < 1e-6 { break }
        }
        return E
    }

    /// Heliocentric (or for Sun/Moon, the body's own-orbit) rectangular ecliptic coords,
    /// plus the true anomaly-derived radius. Returns (xeclip, yeclip, zeclip, r).
    private static func rectangular(_ el: Elements) -> (x: Double, y: Double, z: Double, r: Double) {
        let E = eccentricAnomaly(M: el.M, e: el.e)
        let Erad = E * AstroMath.deg2rad
        // Position in the orbital plane.
        let xv = el.a * (cos(Erad) - el.e)
        let yv = el.a * sqrt(max(1 - el.e * el.e, 0)) * sin(Erad)
        let r = sqrt(xv * xv + yv * yv)
        let v = AstroMath.atan2d(yv, xv)  // true anomaly (deg)

        let vw = (v + el.w) * AstroMath.deg2rad
        let Nrad = el.N * AstroMath.deg2rad
        let irad = el.i * AstroMath.deg2rad

        let x = r * (cos(Nrad) * cos(vw) - sin(Nrad) * sin(vw) * cos(irad))
        let y = r * (sin(Nrad) * cos(vw) + cos(Nrad) * sin(vw) * cos(irad))
        let z = r * (sin(vw) * sin(irad))
        return (x, y, z, r)
    }

    // MARK: Public — full chart

    /// Compute a full chart for a UTC instant, observer latitude/longitude (deg),
    /// and whether the birth time is known (drives Ascendant/MC).
    static func chart(utcDate: Date, latitude: Double, longitude: Double, hasTime: Bool) -> Chart {
        let d = dayNumber(from: utcDate)
        let positions = bodyPositions(d: d)

        guard hasTime else {
            return Chart(positions: positions, ascendant: nil, midheaven: nil)
        }

        let (asc, mc) = ascendantMidheaven(d: d, latitude: latitude, longitude: longitude)
        return Chart(positions: positions, ascendant: asc, midheaven: mc)
    }

    /// Just the geocentric positions at day `d`, with retrograde via a one-day lookback.
    static func bodyPositions(d: Double) -> [BodyPosition] {
        // Sun's geocentric rectangular coords (used to shift heliocentric to geocentric).
        let sunEl = elements(for: .sun, d: d)
        let sunE = eccentricAnomaly(M: sunEl.M, e: sunEl.e)
        let sunErad = sunE * AstroMath.deg2rad
        let sxv = sunEl.a * (cos(sunErad) - sunEl.e)
        let syv = sunEl.a * sqrt(max(1 - sunEl.e * sunEl.e, 0)) * sin(sunErad)
        let sunR = sqrt(sxv * sxv + syv * syv)
        let sunV = AstroMath.atan2d(syv, sxv)
        let lonsun = AstroMath.norm360(sunV + sunEl.w)
        let xs = sunR * AstroMath.cosd(lonsun)
        let ys = sunR * AstroMath.sind(lonsun)

        func geoLongitude(of planet: Planet, atDay dd: Double, sunXS: Double, sunYS: Double, lonsunForSun: Double) -> (lon: Double, dist: Double) {
            switch planet {
            case .sun:
                return (lonsunForSun, sunR)
            case .moon:
                // Moon orbits Earth: its computed rectangular coords are already geocentric.
                let el = elements(for: .moon, d: dd)
                let geo = rectangular(el)
                var lon = AstroMath.atan2d(geo.y, geo.x)
                // Principal lunar perturbations (Schlyter's main terms), in degrees.
                lon = applyMoonPerturbations(longitude: lon, d: dd, el: el)
                let dist = sqrt(geo.x * geo.x + geo.y * geo.y + geo.z * geo.z)
                return (AstroMath.norm360(lon), dist)
            default:
                let el = elements(for: planet, d: dd)
                let helio = rectangular(el)
                let xg = helio.x + sunXS
                let yg = helio.y + sunYS
                let zg = helio.z
                let lon = AstroMath.atan2d(yg, xg)
                let dist = sqrt(xg * xg + yg * yg + zg * zg)
                return (lon, dist)
            }
        }

        // Recompute the Sun's shift at d-1 for retrograde checks of the other planets.
        let prevD = d - 1
        let sunElP = elements(for: .sun, d: prevD)
        let sunEP = eccentricAnomaly(M: sunElP.M, e: sunElP.e)
        let sunEPrad = sunEP * AstroMath.deg2rad
        let sxvP = sunElP.a * (cos(sunEPrad) - sunElP.e)
        let syvP = sunElP.a * sqrt(max(1 - sunElP.e * sunElP.e, 0)) * sin(sunEPrad)
        let sunRP = sqrt(sxvP * sxvP + syvP * syvP)
        let sunVP = AstroMath.atan2d(syvP, sxvP)
        let lonsunP = AstroMath.norm360(sunVP + sunElP.w)
        let xsP = sunRP * AstroMath.cosd(lonsunP)
        let ysP = sunRP * AstroMath.sind(lonsunP)

        var result: [BodyPosition] = []
        for planet in Planet.allCases {
            let today = geoLongitude(of: planet, atDay: d, sunXS: xs, sunYS: ys, lonsunForSun: lonsun)
            let yesterday = geoLongitude(of: planet, atDay: prevD, sunXS: xsP, sunYS: ysP, lonsunForSun: lonsunP)
            // Retrograde: longitude decreasing day-over-day (handle the 360 wrap).
            let delta = AstroMath.norm180(today.lon - yesterday.lon)
            let retro = delta < 0
            result.append(BodyPosition(planet: planet,
                                       longitude: today.lon,
                                       distance: today.dist,
                                       retrograde: retro))
        }
        return result
    }

    /// Apply the principal lunar perturbation terms (Schlyter). Improves the Moon
    /// from ~2° to typically well under 0.5°; minor terms omitted by design.
    private static func applyMoonPerturbations(longitude: Double, d: Double, el: Elements) -> Double {
        // Sun's mean anomaly and mean longitude.
        let sunEl = elements(for: .sun, d: d)
        let Ms = sunEl.M
        let Ls = AstroMath.norm360(sunEl.M + sunEl.w)            // Sun's mean longitude
        let Mm = el.M                                            // Moon's mean anomaly
        let Lm = AstroMath.norm360(el.N + el.w + el.M)           // Moon's mean longitude
        let D = AstroMath.norm360(Lm - Ls)                       // mean elongation
        let F = AstroMath.norm360(Lm - el.N)                     // argument of latitude

        var lon = longitude
        lon += -1.274 * AstroMath.sind(Mm - 2 * D)   // Evection
        lon += +0.658 * AstroMath.sind(2 * D)        // Variation
        lon += -0.186 * AstroMath.sind(Ms)           // Yearly equation
        lon += -0.059 * AstroMath.sind(2 * Mm - 2 * D)
        lon += -0.057 * AstroMath.sind(Mm - 2 * D + Ms)
        lon += +0.053 * AstroMath.sind(Mm + 2 * D)
        lon += +0.046 * AstroMath.sind(2 * D - Ms)
        lon += +0.041 * AstroMath.sind(Mm - Ms)
        lon += -0.035 * AstroMath.sind(D)            // Parallactic equation
        lon += -0.031 * AstroMath.sind(Mm + Ms)
        lon += -0.015 * AstroMath.sind(2 * F - 2 * D)
        lon += +0.011 * AstroMath.sind(Mm - 4 * D)
        return AstroMath.norm360(lon)
    }

    // MARK: Ascendant & Midheaven

    /// Local sidereal time (degrees) and the Ascendant + Midheaven ecliptic longitudes.
    private static func ascendantMidheaven(d: Double, latitude: Double, longitude: Double) -> (asc: Double, mc: Double) {
        let ecl = obliquity(d)

        // Sun's mean longitude → GMST0 (Schlyter): sidereal time at Greenwich at 0h is
        // Ls + 180°. d already includes the UT fraction, so derive UT hours from it.
        let sunEl = elements(for: .sun, d: d)
        let Ls = AstroMath.norm360(sunEl.M + sunEl.w)
        // Fractional part of the day → UT hours.
        let utHours = (d - floor(d)) * 24.0
        let gmst0 = Ls / 15.0 + 12.0                  // hours
        let gmst = gmst0 + utHours                    // Greenwich mean sidereal time (hours)
        let lstDeg = AstroMath.norm360(gmst * 15.0 + longitude)   // local sidereal time (degrees)

        // Midheaven: longitude on the ecliptic at the local meridian.
        let ramc = lstDeg
        let mc = AstroMath.norm360(AstroMath.atan2d(AstroMath.sind(ramc),
                                                    AstroMath.cosd(ramc) * AstroMath.cosd(ecl)))

        // Ascendant via the standard (Meeus) formula:
        //   Asc = atan2( cos(LST), -(sin(LST)·cos(ε) + tan(φ)·sin(ε)) )
        let latRad = latitude * AstroMath.deg2rad
        let lstRad = lstDeg * AstroMath.deg2rad
        let eclRad = ecl * AstroMath.deg2rad
        let y = cos(lstRad)
        let x = -(sin(lstRad) * cos(eclRad) + tan(latRad) * sin(eclRad))
        let asc = AstroMath.atan2d(y, x)
        return (AstroMath.norm360(asc), mc)
    }
}
