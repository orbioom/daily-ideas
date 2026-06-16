import Foundation

/// A single transit: a transiting (sky) body forming an aspect to a natal body.
struct TransitHit: Identifiable {
    let id = UUID()
    let transiting: Planet
    let natal: Planet
    let kind: AspectKind
    let orb: Double
    /// A weight used to pick "the strongest transit" — tighter + faster-mover = stronger.
    let weight: Double

    var headline: String {
        "\(transiting.name) \(kind.rawValue.lowercased()) your \(natal.name)"
    }
}

/// The deterministic daily reading for a profile, grounded in real transits.
struct DailyReading {
    let moonSign: ZodiacSign
    let strongest: TransitHit?
    let body: String
    /// A short multi-day outlook (Pro): one line per upcoming day.
    let outlook: [OutlookDay]
}

struct OutlookDay: Identifiable {
    let id = UUID()
    let date: Date
    let moonSign: ZodiacSign
    let headline: String
}

enum TransitEngine {

    /// Compute today's transits to a natal chart and the grounded reading.
    static func reading(natal: Chart, on date: Date, baseOrb: Double, includeOutlook: Bool) -> DailyReading {
        let dToday = Ephemeris.dayNumber(from: date)
        let sky = Ephemeris.bodyPositions(d: dToday)
        let moonSign = sky.first(where: { $0.planet == .moon })?.sign ?? .aries

        let transits = transitHits(sky: sky, natal: natal.positions, baseOrb: baseOrb)
        let strongest = transits.max(by: { $0.weight < $1.weight })

        let body = readingText(strongest: strongest, moonSign: moonSign)

        var outlook: [OutlookDay] = []
        if includeOutlook {
            let cal = Calendar.current
            for offset in 1...5 {
                guard let day = cal.date(byAdding: .day, value: offset, to: date) else { continue }
                let dd = Ephemeris.dayNumber(from: day)
                let daySky = Ephemeris.bodyPositions(d: dd)
                let dayMoon = daySky.first(where: { $0.planet == .moon })?.sign ?? .aries
                let dayTransits = transitHits(sky: daySky, natal: natal.positions, baseOrb: baseOrb)
                let top = dayTransits.max(by: { $0.weight < $1.weight })
                let line = top?.headline ?? "Moon in \(dayMoon.name) — a \(dayMoon.keywords.first ?? "steady") day"
                outlook.append(OutlookDay(date: day, moonSign: dayMoon, headline: line))
            }
        }

        return DailyReading(moonSign: moonSign, strongest: strongest, body: body, outlook: outlook)
    }

    static func transitHits(sky: [BodyPosition], natal: [BodyPosition], baseOrb: Double) -> [TransitHit] {
        var hits: [TransitHit] = []
        for t in sky {
            for n in natal {
                let sep = AstroMath.separation(t.longitude, n.longitude)
                let involvesLuminary = t.planet.isLuminary || n.planet.isLuminary
                for kind in AspectKind.allCases {
                    let allowed = kind.orb(involvingLuminary: involvesLuminary, base: baseOrb)
                    let delta = abs(sep - kind.angle)
                    if delta <= allowed {
                        let weight = transitWeight(transiting: t.planet, natal: n.planet, orb: delta, allowed: allowed)
                        hits.append(TransitHit(transiting: t.planet, natal: n.planet, kind: kind, orb: delta, weight: weight))
                    }
                }
            }
        }
        return hits.sorted { $0.weight > $1.weight }
    }

    /// Stronger when tighter, when the transiting body is slow (rarer event),
    /// and when a luminary is involved.
    private static func transitWeight(transiting: Planet, natal: Planet, orb: Double, allowed: Double) -> Double {
        let tightness = allowed > 0 ? (1 - orb / allowed) : 0   // 0..1, guarded
        let slowness: Double
        switch transiting {
        case .moon: slowness = 0.4
        case .sun, .mercury, .venus: slowness = 0.7
        case .mars: slowness = 1.0
        case .jupiter, .saturn: slowness = 1.6
        case .uranus, .neptune, .pluto: slowness = 2.0
        }
        let luminaryBoost = (transiting.isLuminary || natal.isLuminary) ? 1.3 : 1.0
        return tightness * slowness * luminaryBoost
    }

    /// Grounded, deterministic copy keyed to the strongest transit + the Moon's sign.
    /// Calm and specific — never random doom.
    private static func readingText(strongest: TransitHit?, moonSign: ZodiacSign) -> String {
        let moonLine = "The Moon is in \(moonSign.name) today, so the emotional weather leans \(moonSign.keywords.joined(separator: ", ")). "

        guard let t = strongest else {
            return moonLine + "No tight transit to your chart right now — a quiet, open day to set your own tone."
        }

        let aspectFlavor: String
        switch t.kind {
        case .conjunction:
            aspectFlavor = "fuses with"
        case .sextile:
            aspectFlavor = "opens a door to"
        case .trine:
            aspectFlavor = "flows easily into"
        case .square:
            aspectFlavor = "presses on"
        case .opposition:
            aspectFlavor = "pulls against"
        }

        let theme = "\(t.transiting.name) (\(t.transiting.keywords.first ?? "energy")) \(aspectFlavor) your natal \(t.natal.name) (\(t.natal.keywords.first ?? "self")). "

        let guidance: String
        if t.kind.isChallenging {
            guidance = "It's a friction point, not a threat — a place to grow if you meet it consciously today rather than push it down."
        } else if t.kind == .conjunction {
            guidance = "These two are working as one — a concentrated, vivid theme to lean into deliberately."
        } else {
            guidance = "Support is available here; a small, intentional step in this area goes further than usual today."
        }

        return moonLine + theme + guidance
    }
}
