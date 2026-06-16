import Foundation

/// Equatorial coordinates (right ascension / declination), degrees.
struct EquatorialCoord: Equatable {
    /// Right ascension in degrees [0,360).
    var raDeg: Double
    /// Declination in degrees [-90,90].
    var decDeg: Double

    /// Right ascension in hours [0,24).
    var raHours: Double { AstroMath.normalize24(raDeg / 15.0) }
}

/// Horizontal coordinates (altitude / azimuth), degrees.
struct HorizontalCoord: Equatable {
    /// Altitude above the horizon in degrees [-90,90]. Negative = below horizon.
    var altitude: Double
    /// Azimuth in degrees [0,360), measured from North through East.
    var azimuth: Double

    var isAboveHorizon: Bool { altitude > 0 }

    /// Cardinal/intercardinal compass name for the azimuth.
    var compass: String {
        let names = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let idx = Int((AstroMath.normalize360(azimuth) + 22.5) / 45.0) % 8
        return names[max(0, min(7, idx))]
    }

    /// A fuller compass description, e.g. "ESE".
    var compass16: String {
        let names = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                     "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let idx = Int((AstroMath.normalize360(azimuth) + 11.25) / 22.5) % 16
        return names[max(0, min(15, idx))]
    }
}

/// Ecliptic spherical position used internally by the ephemeris.
struct EclipticCoord {
    /// Geocentric ecliptic longitude in degrees [0,360).
    var longitude: Double
    /// Geocentric ecliptic latitude in degrees.
    var latitude: Double
    /// Distance in AU (or Earth radii for the Moon); used for ordering/scale only.
    var distance: Double
}

enum CoordTransform {
    /// Convert geocentric ecliptic longitude/latitude to equatorial RA/Dec
    /// using the obliquity of the ecliptic (degrees).
    static func eclipticToEquatorial(_ e: EclipticCoord, obliquity ecl: Double) -> EquatorialCoord {
        let lon = e.longitude
        let lat = e.latitude
        let sinDec = AstroMath.sind(lat) * AstroMath.cosd(ecl)
            + AstroMath.cosd(lat) * AstroMath.sind(ecl) * AstroMath.sind(lon)
        let dec = AstroMath.asind(sinDec)
        let y = AstroMath.cosd(lat) * AstroMath.sind(lon) * AstroMath.cosd(ecl)
            - AstroMath.sind(lat) * AstroMath.sind(ecl)
        let x = AstroMath.cosd(lat) * AstroMath.cosd(lon)
        let ra = AstroMath.atan2d(y, x)
        return EquatorialCoord(raDeg: ra, decDeg: dec)
    }

    /// Convert equatorial RA/Dec to horizontal alt/az for an observer.
    /// - Parameters:
    ///   - eq: equatorial coordinates (degrees)
    ///   - lstHours: local sidereal time in hours
    ///   - latitude: observer latitude in degrees (north positive)
    static func equatorialToHorizontal(_ eq: EquatorialCoord, lstHours: Double, latitude: Double) -> HorizontalCoord {
        // Hour angle in degrees.
        let haDeg = AstroMath.normalize180(lstHours * 15.0 - eq.raDeg)
        let sinAlt = AstroMath.sind(eq.decDeg) * AstroMath.sind(latitude)
            + AstroMath.cosd(eq.decDeg) * AstroMath.cosd(latitude) * AstroMath.cosd(haDeg)
        let alt = AstroMath.asind(sinAlt)
        // Azimuth measured from North, through East.
        let y = -AstroMath.cosd(eq.decDeg) * AstroMath.cosd(latitude) * AstroMath.sind(haDeg)
        let x = AstroMath.sind(eq.decDeg) - AstroMath.sind(latitude) * sinAlt
        let az = AstroMath.atan2d(y, x)
        return HorizontalCoord(altitude: alt, azimuth: az)
    }
}
