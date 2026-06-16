import Foundation

/// Rise / transit / set events for a body over one local day.
struct RiseSetEvent {
    var rise: Date?
    var transit: Date?
    var set: Date?
    /// True if the body never sets (circumpolar) on this day.
    var alwaysUp: Bool
    /// True if the body never rises on this day.
    var alwaysDown: Bool
}

enum RiseSetEngine {
    /// Altitude (degrees) of a body at an instant for an observer.
    static func altitude(of body: SolarBody, at date: Date, latitude: Double, longitude: Double) -> Double {
        let eq = Ephemeris.equatorial(for: body, at: date)
        let lst = JulianDate.lmstHours(from: date, longitudeEast: longitude)
        return CoordTransform.equatorialToHorizontal(eq, lstHours: lst, latitude: latitude).altitude
    }

    /// Altitude (degrees) of a fixed equatorial point (catalog star).
    static func altitude(of eq: EquatorialCoord, at date: Date, latitude: Double, longitude: Double) -> Double {
        let lst = JulianDate.lmstHours(from: date, longitudeEast: longitude)
        return CoordTransform.equatorialToHorizontal(eq, lstHours: lst, latitude: latitude).altitude
    }

    /// Standard refraction-adjusted horizon altitude for each body.
    private static func horizonAltitude(for body: SolarBody) -> Double {
        switch body {
        case .sun: return -0.833   // upper limb + refraction
        case .moon: return 0.125   // approximate: refraction minus parallax/semidiameter
        default: return -0.5667    // atmospheric refraction for point sources
        }
    }

    /// Compute rise/transit/set for a body across the local day containing `date`.
    /// Steps every 10 minutes from local midnight, detecting altitude zero-crossings
    /// and the altitude maximum (transit). Fully guarded.
    static func events(for body: SolarBody, on date: Date, latitude: Double, longitude: Double, timeZone: TimeZone) -> RiseSetEvent {
        let horizon = horizonAltitude(for: body)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let startOfDay = cal.startOfDay(for: date)

        let stepMinutes = 10.0
        let steps = Int(24.0 * 60.0 / stepMinutes)

        var rise: Date?
        var setTime: Date?
        var transit: Date?
        var maxAlt = -91.0
        var prevAlt = altitude(of: body, at: startOfDay, latitude: latitude, longitude: longitude)
        var prevTime = startOfDay
        var sawAbove = prevAlt > horizon
        var sawBelow = prevAlt <= horizon

        for i in 1...steps {
            let t = startOfDay.addingTimeInterval(Double(i) * stepMinutes * 60)
            let alt = altitude(of: body, at: t, latitude: latitude, longitude: longitude)

            if alt > maxAlt {
                maxAlt = alt
                transit = t
            }
            if alt > horizon { sawAbove = true } else { sawBelow = true }

            // Crossing upward → rise; downward → set.
            if rise == nil, prevAlt <= horizon, alt > horizon {
                rise = refineCrossing(body: body, target: horizon,
                                      lo: prevTime, hi: t,
                                      latitude: latitude, longitude: longitude, rising: true)
            }
            if prevAlt > horizon, alt <= horizon {
                setTime = refineCrossing(body: body, target: horizon,
                                         lo: prevTime, hi: t,
                                         latitude: latitude, longitude: longitude, rising: false)
            }
            prevAlt = alt
            prevTime = t
        }

        let alwaysUp = sawAbove && !sawBelow
        let alwaysDown = sawBelow && !sawAbove
        return RiseSetEvent(rise: rise, transit: transit, set: setTime,
                            alwaysUp: alwaysUp, alwaysDown: alwaysDown)
    }

    /// Bisection to pin a horizon crossing between two times.
    private static func refineCrossing(body: SolarBody, target: Double,
                                       lo: Date, hi: Date,
                                       latitude: Double, longitude: Double,
                                       rising: Bool) -> Date {
        var a = lo
        var b = hi
        for _ in 0..<24 {
            let mid = a.addingTimeInterval(b.timeIntervalSince(a) / 2)
            let alt = altitude(of: body, at: mid, latitude: latitude, longitude: longitude)
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
