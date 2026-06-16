import SwiftUI

/// The observing context: where and when.
struct ObserverContext: Equatable {
    var name: String
    var latitude: Double
    var longitude: Double
    var date: Date
    var timeZone: TimeZone

    static func == (lhs: ObserverContext, rhs: ObserverContext) -> Bool {
        lhs.name == rhs.name &&
        lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude &&
        abs(lhs.date.timeIntervalSince(rhs.date)) < 1 &&
        lhs.timeZone == rhs.timeZone
    }
}

/// A complete computed snapshot of the sky for one observer context.
struct SkySnapshot {
    let context: ObserverContext
    let planets: [SkyObject]      // Sun, Moon, planets
    let stars: [SkyObject]        // catalogue stars (with current alt/az)
    let moonPhase: MoonPhase
    let twilight: TwilightTimes

    /// Best objects up now — brightest visible planets + stars, sorted by magnitude.
    var bestUpNow: [SkyObject] {
        let up = (planets + stars).filter { $0.isAboveHorizon && $0.kind != .sun }
        return up.sorted { $0.magnitude < $1.magnitude }
    }

    var planetsUp: [SkyObject] {
        planets.filter { $0.isAboveHorizon && $0.kind == .planet }
    }
}

/// Top-level engine that turns an ObserverContext into a SkySnapshot.
enum SkyEngine {

    /// The solar bodies plotted (outer ice giants gated behind Pro in the views).
    static let plottedBodies: [SolarBody] = [
        .sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune
    ]

    /// Compute a full snapshot. Pure & guarded; safe to run off the main thread.
    static func snapshot(for context: ObserverContext, magnitudeLimit: Double, includeOuterPlanets: Bool) -> SkySnapshot {
        let lst = JulianDate.lmstHours(from: context.date, longitudeEast: context.longitude)

        var planetObjects: [SkyObject] = []
        for body in plottedBodies {
            if body.isOuterIce && !includeOuterPlanets { continue }
            let eq = Ephemeris.equatorial(for: body, at: context.date)
            let hz = CoordTransform.equatorialToHorizontal(eq, lstHours: lst, latitude: context.latitude)
            let kind: SkyObjectKind = body == .sun ? .sun : (body == .moon ? .moon : .planet)
            planetObjects.append(
                SkyObject(
                    id: "body.\(body.rawValue)",
                    name: body.displayName,
                    kind: kind,
                    constellation: "",
                    magnitude: body.nominalMagnitude,
                    equatorial: eq,
                    horizontal: hz,
                    tint: SkyObject.tint(for: body),
                    body: body,
                    starID: nil,
                    summary: SkyObject.planetSummary(body)
                )
            )
        }

        var starObjects: [SkyObject] = []
        for star in Catalog.stars where star.magnitude <= magnitudeLimit {
            let hz = CoordTransform.equatorialToHorizontal(star.equatorial, lstHours: lst, latitude: context.latitude)
            starObjects.append(
                SkyObject(
                    id: "star.\(star.id)",
                    name: star.displayName,
                    kind: .star,
                    constellation: star.constellation,
                    magnitude: star.magnitude,
                    equatorial: star.equatorial,
                    horizontal: hz,
                    tint: starTint(for: star.magnitude),
                    body: nil,
                    starID: star.id,
                    summary: "\(star.bayer) — a bright star in \(star.constellation)."
                )
            )
        }

        let phase = MoonPhaseEngine.phase(at: context.date)
        let twilight = TwilightEngine.times(on: context.date,
                                            latitude: context.latitude,
                                            longitude: context.longitude,
                                            timeZone: context.timeZone)

        return SkySnapshot(context: context,
                           planets: planetObjects,
                           stars: starObjects,
                           moonPhase: phase,
                           twilight: twilight)
    }

    /// Horizontal position for a catalogue star at the context instant.
    static func horizontal(for star: CatalogStar, context: ObserverContext) -> HorizontalCoord {
        let lst = JulianDate.lmstHours(from: context.date, longitudeEast: context.longitude)
        return CoordTransform.equatorialToHorizontal(star.equatorial, lstHours: lst, latitude: context.latitude)
    }

    private static func starTint(for magnitude: Double) -> Color {
        // Brighter stars slightly warmer-white; faint ones cooler-dim.
        magnitude < 1.0 ? Color(hex: 0xFFFFFF) : Color(hex: 0xD8E4F2)
    }
}
