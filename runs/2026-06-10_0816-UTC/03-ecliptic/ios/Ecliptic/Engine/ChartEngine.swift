import Foundation

// MARK: - Zodiac

enum Sign: Int, CaseIterable, Identifiable {
    case aries, taurus, gemini, cancer, leo, virgo
    case libra, scorpio, sagittarius, capricorn, aquarius, pisces

    var id: Int { rawValue }

    static func at(longitude: Double) -> Sign {
        Sign(rawValue: Int(Astronomy.norm(longitude) / 30) % 12) ?? .aries
    }

    var name: String {
        ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
         "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"][rawValue]
    }

    var glyph: String {
        ["♈", "♉", "♊", "♋", "♌", "♍", "♎", "♏", "♐", "♑", "♒", "♓"][rawValue]
    }

    var element: String {
        ["Fire", "Earth", "Air", "Water"][rawValue % 4]
    }

    var modality: String {
        ["Cardinal", "Fixed", "Mutable"][rawValue % 3]
    }

    /// The sign's expressive style, used to compose placement readings.
    var style: String {
        ["direct, fast-burning, pioneering",
         "steady, sensual, patient",
         "curious, quick, many-threaded",
         "protective, intuitive, tidal",
         "warm, expressive, generous",
         "precise, helpful, discerning",
         "balanced, relational, fair-minded",
         "intense, private, transformative",
         "expansive, candid, far-roaming",
         "disciplined, ambitious, dry-witted",
         "independent, inventive, communal",
         "porous, imaginative, compassionate"][rawValue]
    }
}

// MARK: - Planets

enum Planet: String, CaseIterable, Identifiable {
    case sun, moon, mercury, venus, mars, jupiter, saturn, uranus, neptune, pluto

    var id: String { rawValue }

    var name: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }

    var glyph: String {
        switch self {
        case .sun: return "☉"
        case .moon: return "☽"
        case .mercury: return "☿"
        case .venus: return "♀"
        case .mars: return "♂"
        case .jupiter: return "♃"
        case .saturn: return "♄"
        case .uranus: return "♅"
        case .neptune: return "♆"
        case .pluto: return "♇"
        }
    }

    /// What this planet governs, used to compose readings.
    var theme: String {
        switch self {
        case .sun: return "your core identity and vitality"
        case .moon: return "your instincts and emotional weather"
        case .mercury: return "how you think, learn, and speak"
        case .venus: return "how you love, relate, and value"
        case .mars: return "your drive, anger, and desire"
        case .jupiter: return "where you expand, trust, and find luck"
        case .saturn: return "where you structure, limit, and commit"
        case .uranus: return "where you break pattern and rebel"
        case .neptune: return "where you dream, dissolve, and idealise"
        case .pluto: return "where you face power and transform"
        }
    }

    var isClassical: Bool {
        switch self {
        case .uranus, .neptune, .pluto: return false
        default: return true
        }
    }

    func longitude(jd: Double) -> Double {
        switch self {
        case .sun: return Astronomy.sunLongitude(jd: jd)
        case .moon: return Astronomy.moonLongitude(jd: jd)
        case .mercury: return Astronomy.planetLongitude(.mercury, jd: jd)
        case .venus: return Astronomy.planetLongitude(.venus, jd: jd)
        case .mars: return Astronomy.planetLongitude(.mars, jd: jd)
        case .jupiter: return Astronomy.planetLongitude(.jupiter, jd: jd)
        case .saturn: return Astronomy.planetLongitude(.saturn, jd: jd)
        case .uranus: return Astronomy.planetLongitude(.uranus, jd: jd)
        case .neptune: return Astronomy.planetLongitude(.neptune, jd: jd)
        case .pluto: return Astronomy.planetLongitude(.pluto, jd: jd)
        }
    }
}

// MARK: - Positions

struct PlanetPosition: Identifiable {
    let planet: Planet
    let longitude: Double

    var id: String { planet.rawValue }
    var sign: Sign { Sign.at(longitude: longitude) }
    var degreeInSign: Double { Astronomy.norm(longitude).truncatingRemainder(dividingBy: 30) }

    var formattedDegree: String {
        let deg = Int(degreeInSign)
        let min = Int((degreeInSign - Double(deg)) * 60)
        return "\(deg)°\(String(format: "%02d", min))′"
    }

    /// "Mars in Taurus 16°01′"
    var summary: String { "\(planet.name) in \(sign.name) \(formattedDegree)" }

    var meaning: String {
        let theme = planet.theme
        return theme.prefix(1).uppercased() + theme.dropFirst()
            + " expresses through \(sign.name): \(sign.style)."
    }
}

// MARK: - Aspects

enum AspectKind: CaseIterable {
    case conjunction, sextile, square, trine, opposition

    var angle: Double {
        switch self {
        case .conjunction: return 0
        case .sextile: return 60
        case .square: return 90
        case .trine: return 120
        case .opposition: return 180
        }
    }

    var orb: Double {
        switch self {
        case .conjunction, .opposition: return 8
        case .square, .trine: return 7
        case .sextile: return 5
        }
    }

    var name: String {
        switch self {
        case .conjunction: return "Conjunction"
        case .sextile: return "Sextile"
        case .square: return "Square"
        case .trine: return "Trine"
        case .opposition: return "Opposition"
        }
    }

    var glyph: String {
        switch self {
        case .conjunction: return "☌"
        case .sextile: return "✶"
        case .square: return "□"
        case .trine: return "△"
        case .opposition: return "☍"
        }
    }

    var verb: String {
        switch self {
        case .conjunction: return "fuses with"
        case .sextile: return "supports"
        case .square: return "challenges"
        case .trine: return "flows with"
        case .opposition: return "faces off with"
        }
    }

    var isHarmonious: Bool {
        switch self {
        case .sextile, .trine: return true
        default: return false
        }
    }
}

struct Aspect: Identifiable {
    let a: Planet
    let b: Planet
    let kind: AspectKind
    let orb: Double          // deviation from exact, degrees

    var id: String { "\(a.rawValue)-\(kind.name)-\(b.rawValue)" }
    var summary: String { "\(a.name) \(kind.glyph) \(b.name)" }
}

// MARK: - Houses

enum HouseSystem: String, CaseIterable, Identifiable {
    case wholeSign, equal

    var id: String { rawValue }
    var label: String { self == .wholeSign ? "Whole sign" : "Equal house" }
    var explanation: String {
        self == .wholeSign
        ? "Each house is one whole sign, starting from the rising sign — the oldest system, and the one Ecliptic defaults to."
        : "Twelve equal 30° houses measured from the exact ascendant degree."
    }
}

// MARK: - Chart

struct Chart {
    let positions: [PlanetPosition]
    let ascendant: Double?      // nil when birth time unknown
    let midheaven: Double?
    let aspects: [Aspect]
    let houseSystem: HouseSystem

    var risingSign: Sign? { ascendant.map { Sign.at(longitude: $0) } }

    /// House number 1–12 for an ecliptic longitude, if houses are available.
    func house(of longitude: Double) -> Int? {
        guard let asc = ascendant else { return nil }
        switch houseSystem {
        case .wholeSign:
            let ascSign = Int(Astronomy.norm(asc) / 30)
            let posSign = Int(Astronomy.norm(longitude) / 30)
            return ((posSign - ascSign + 12) % 12) + 1
        case .equal:
            let delta = Astronomy.norm(longitude - asc)
            return Int(delta / 30) + 1
        }
    }
}

enum ChartEngine {

    static let houseMeanings: [String] = [
        "Self — body, appearance, the way you arrive",
        "Resources — money, possessions, self-worth",
        "Mind — siblings, neighbours, daily communication",
        "Roots — home, family, where you come from",
        "Joy — creativity, romance, children, play",
        "Craft — work, habits, health, daily service",
        "Others — partnership, marriage, open rivals",
        "Depths — shared resources, intimacy, loss and renewal",
        "Horizon — travel, philosophy, higher learning",
        "Calling — career, reputation, public life",
        "Allies — friends, groups, hopes for the future",
        "Undertow — solitude, secrets, the unconscious"
    ]

    static func positions(jd: Double, includeModern: Bool) -> [PlanetPosition] {
        Planet.allCases
            .filter { includeModern || $0.isClassical }
            .map { PlanetPosition(planet: $0, longitude: $0.longitude(jd: jd)) }
    }

    static func chart(birthDate: Date, latitude: Double, longitude: Double,
                      timeKnown: Bool, houseSystem: HouseSystem,
                      includeModern: Bool) -> Chart {
        let jd = Astronomy.julianDay(birthDate)
        let pos = positions(jd: jd, includeModern: includeModern)
        let asc = timeKnown ? Astronomy.ascendant(jd: jd, latitude: latitude, longitude: longitude) : nil
        let mc = timeKnown ? Astronomy.midheaven(jd: jd, longitude: longitude) : nil
        return Chart(positions: pos, ascendant: asc, midheaven: mc,
                     aspects: aspects(in: pos), houseSystem: houseSystem)
    }

    /// All natal aspects, tightest first.
    static func aspects(in positions: [PlanetPosition]) -> [Aspect] {
        var found: [Aspect] = []
        for i in positions.indices {
            for j in positions.indices where j > i {
                let sep = separation(positions[i].longitude, positions[j].longitude)
                if let (kind, orb) = match(separation: sep) {
                    found.append(Aspect(a: positions[i].planet, b: positions[j].planet,
                                        kind: kind, orb: orb))
                }
            }
        }
        return found.sorted { $0.orb < $1.orb }
    }

    /// Transiting-sky aspects to natal placements, within a tight orb.
    static func transits(natal: [PlanetPosition], sky: [PlanetPosition],
                         maxOrb: Double = 3) -> [TransitHit] {
        var hits: [TransitHit] = []
        for t in sky {
            for n in natal {
                let sep = separation(t.longitude, n.longitude)
                if let (kind, orb) = match(separation: sep), orb <= maxOrb {
                    hits.append(TransitHit(transiting: t, natal: n, kind: kind, orb: orb))
                }
            }
        }
        return hits.sorted { $0.orb < $1.orb }
    }

    static func separation(_ a: Double, _ b: Double) -> Double {
        let d = abs(Astronomy.norm(a) - Astronomy.norm(b))
        return min(d, 360 - d)
    }

    static func match(separation: Double) -> (AspectKind, Double)? {
        var best: (AspectKind, Double)?
        for kind in AspectKind.allCases {
            let orb = abs(separation - kind.angle)
            guard orb <= kind.orb else { continue }
            if let current = best {
                if orb < current.1 { best = (kind, orb) }
            } else {
                best = (kind, orb)
            }
        }
        return best
    }
}

struct TransitHit: Identifiable {
    let transiting: PlanetPosition
    let natal: PlanetPosition
    let kind: AspectKind
    let orb: Double

    var id: String { "\(transiting.planet.rawValue)-\(kind.name)-\(natal.planet.rawValue)" }

    var headline: String {
        "\(transiting.planet.name) \(kind.verb) your \(natal.planet.name)"
    }

    var detail: String {
        let theme = natal.planet.theme
        let tone: String
        switch kind {
        case .conjunction: tone = "A new cycle begins around"
        case .sextile: tone = "An easy opening appears around"
        case .square: tone = "Productive friction builds around"
        case .trine: tone = "Things move without forcing around"
        case .opposition: tone = "Something asks for balance around"
        }
        return "\(tone) \(theme). (\(kind.name.lowercased()), orb \(String(format: "%.1f", orb))°)"
    }
}
