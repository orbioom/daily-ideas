import Foundation

/// One compared facet between two profiles.
struct CompatibilityPair: Identifiable, Equatable {
    let position: NumberPosition
    let valueA: Int
    let valueB: Int
    let score: Int          // 0–100 for this facet
    let note: String        // per-pair explanation
    var id: String { position.rawValue }
}

/// The full compatibility result between two profiles.
struct CompatibilityResult: Equatable {
    let nameA: String
    let nameB: String
    let pairs: [CompatibilityPair]
    let overall: Int        // 0–100 weighted harmony score
    let headline: String    // a one-line summary
    let summary: String     // a substantive paragraph

    var band: CompatibilityBand { CompatibilityBand(score: overall) }
}

enum CompatibilityBand: String {
    case soulmates = "Deeply Aligned"
    case strong = "Strong Harmony"
    case balanced = "Balanced"
    case growth = "Growth Pairing"
    case challenging = "A Teaching Bond"

    init(score: Int) {
        switch score {
        case 85...100: self = .soulmates
        case 70..<85: self = .strong
        case 55..<70: self = .balanced
        case 40..<55: self = .growth
        default: self = .challenging
        }
    }
}

/// Pure compatibility scoring. Transparent rule documented inline.
enum CompatibilityEngine {

    /// Facet weights — Life Path matters most, then Expression, then Soul Urge.
    private static let weights: [NumberPosition: Double] = [
        .lifePath: 0.45,
        .expression: 0.30,
        .soulUrge: 0.25
    ]

    /// Score two single numbers 0–100 with a transparent, deterministic rule:
    /// • identical numbers → 100 (perfect resonance)
    /// • numbers reducing to the same root → 88
    /// • classic compatible pairs (e.g. 2&6, 3&9) → 78
    /// • otherwise distance-based: closer roots score higher.
    static func facetScore(_ a: Int, _ b: Int) -> Int {
        if a == b { return 100 }
        let ra = singleRoot(a)
        let rb = singleRoot(b)
        if ra == rb { return 88 }
        if compatiblePairs.contains(Pair(ra, rb)) { return 78 }
        if challengingPairs.contains(Pair(ra, rb)) { return 38 }
        // Distance on a 1–9 ring; opposite values score lowest.
        let raw = abs(ra - rb)
        let ringDistance = min(raw, 9 - raw)            // 0…4
        let normalized = 1.0 - Double(ringDistance) / 4.0 // 1.0…0.0
        return Int((45 + normalized * 30).rounded())      // 45…75
    }

    private static func singleRoot(_ n: Int) -> Int {
        var v = abs(n)
        while v > 9 { v = String(v).compactMap { $0.wholeNumberValue }.reduce(0, +) }
        return max(1, v)
    }

    private struct Pair: Hashable {
        let lo: Int, hi: Int
        init(_ a: Int, _ b: Int) { lo = min(a, b); hi = max(a, b) }
    }

    /// Numbers that traditionally flow well together.
    private static let compatiblePairs: Set<Pair> = [
        Pair(1, 5), Pair(1, 7), Pair(2, 6), Pair(2, 8), Pair(3, 6),
        Pair(3, 9), Pair(4, 8), Pair(5, 7), Pair(6, 9), Pair(1, 9)
    ]

    /// Numbers that tend to grind against each other.
    private static let challengingPairs: Set<Pair> = [
        Pair(1, 4), Pair(1, 8), Pair(2, 5), Pair(4, 5), Pair(3, 4)
    ]

    static func compatibility(between a: Profile, and b: Profile, config: NumerologyConfig) -> CompatibilityResult {
        let chartA = NumerologyEngine.chart(for: a, config: config)
        let chartB = NumerologyEngine.chart(for: b, config: config)

        let positions: [(NumberPosition, CoreNumber, CoreNumber)] = [
            (.lifePath, chartA.lifePath, chartB.lifePath),
            (.expression, chartA.expression, chartB.expression),
            (.soulUrge, chartA.soulUrge, chartB.soulUrge)
        ]

        var pairs: [CompatibilityPair] = []
        var weightedTotal = 0.0
        for (pos, ca, cb) in positions {
            let s = facetScore(ca.value, cb.value)
            let w = weights[pos] ?? 0.33
            weightedTotal += Double(s) * w
            pairs.append(CompatibilityPair(
                position: pos,
                valueA: ca.value,
                valueB: cb.value,
                score: s,
                note: note(for: pos, a: ca.value, b: cb.value, score: s, nameA: a.displayName, nameB: b.displayName)
            ))
        }

        let overall = max(0, min(100, Int(weightedTotal.rounded())))
        let band = CompatibilityBand(score: overall)
        let headline = "\(a.displayName) & \(b.displayName): \(band.rawValue)"
        return CompatibilityResult(
            nameA: a.displayName,
            nameB: b.displayName,
            pairs: pairs,
            overall: overall,
            headline: headline,
            summary: summary(band: band, pairs: pairs, nameA: a.displayName, nameB: b.displayName)
        )
    }

    private static func note(for position: NumberPosition, a: Int, b: Int, score: Int, nameA: String, nameB: String) -> String {
        let facet: String
        switch position {
        case .lifePath: facet = "life direction"
        case .expression: facet = "how you each build a life"
        case .soulUrge: facet = "what your hearts long for"
        default: facet = "this facet"
        }
        if a == b {
            return "You share a \(position.rawValue) of \(a) — a natural resonance in \(facet)."
        }
        switch score {
        case 80...100: return "\(a) and \(b) blend easily here; your \(facet) reinforce one another."
        case 60..<80: return "\(a) and \(b) complement each other in \(facet) with a little give and take."
        case 45..<60: return "\(a) and \(b) differ in \(facet) — workable, but it asks for understanding."
        default: return "\(a) and \(b) pull in different directions in \(facet); this is where the relationship teaches you both."
        }
    }

    private static func summary(band: CompatibilityBand, pairs: [CompatibilityPair], nameA: String, nameB: String) -> String {
        let strongest = pairs.max(by: { $0.score < $1.score })
        let weakest = pairs.min(by: { $0.score < $1.score })
        let strongLine = strongest.map { "Your strongest thread is \($0.position.rawValue), where \($0.valueA) and \($0.valueB) move together." } ?? ""
        let growthLine = weakest.map { "The growth edge is \($0.position.rawValue) — \($0.valueA) and \($0.valueB) ask you to translate for one another." } ?? ""
        switch band {
        case .soulmates:
            return "\(nameA) and \(nameB) share a rare numeric resonance. \(strongLine) Bonds this aligned feel effortless, though even they thrive on small, deliberate appreciation."
        case .strong:
            return "\(nameA) and \(nameB) form a genuinely harmonious pairing. \(strongLine) \(growthLine)"
        case .balanced:
            return "\(nameA) and \(nameB) balance one another — neither identical nor opposed. \(strongLine) \(growthLine)"
        case .growth:
            return "\(nameA) and \(nameB) are a growth pairing: real attraction with real differences. \(strongLine) \(growthLine)"
        case .challenging:
            return "\(nameA) and \(nameB) form a teaching bond. The contrasts here are not flaws but lessons. \(growthLine) Met with patience, opposite numbers often forge the most transformative relationships."
        }
    }
}
