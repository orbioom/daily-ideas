import Foundation

/// Descriptor band for a single trait score.
enum TraitBand: String {
    case low = "Lower"
    case moderate = "Moderate"
    case high = "Higher"

    static func from(score: Double) -> TraitBand {
        switch score {
        case ..<40: return .low
        case 40..<60: return .moderate
        default: return .high
        }
    }
}

/// A single trait's normalized result.
struct TraitScore: Identifiable {
    let trait: Trait
    /// Normalized 0–100.
    let score: Double
    var id: String { trait.rawValue }
    var band: TraitBand { TraitBand.from(score: score) }

    /// Friendly descriptor for the trait given its band.
    var descriptor: String {
        switch band {
        case .low: return trait.lowPole
        case .moderate: return "Balanced"
        case .high: return trait.highPole
        }
    }
}

/// The complete deterministic result of scoring a set of responses.
struct ScoredResult {
    let traitScores: [TraitScore]
    let typeCode: String

    func score(for trait: Trait) -> Double {
        traitScores.first { $0.trait == trait }?.score ?? 50
    }

    var archetype: Archetype { Archetype.forCode(typeCode) }
}

/// Pure, deterministic scoring of IPIP Likert responses.
///
/// Method (documented & transparent):
/// - Each trait has 8 items, answered on a 1–5 Likert scale (1 = Disagree … 5 = Agree).
/// - Reverse-keyed items are recoded as (6 − response).
/// - The 8 recoded items are summed (range 8–40) and linearly normalized to 0–100:
///   `normalized = (sum − 8) / (40 − 8) * 100`. The neutral midpoint (all 3s) maps to 50.
enum ScoringEngine {
    static let itemsPerTrait = 8
    static let minRaw = 8.0   // 8 items × 1
    static let maxRaw = 40.0  // 8 items × 5

    /// Scores a complete response set. Missing answers default to the neutral 3 so the
    /// engine never crashes, but callers should require completeness before persisting.
    static func score(responses: [Int: Int]) -> ScoredResult {
        var traitScores: [TraitScore] = []

        for trait in Trait.allCases {
            let traitItems = ItemBank.items.filter { $0.trait == trait }
            var raw = 0.0
            for item in traitItems {
                let answered = responses[item.id]
                // Clamp any out-of-range value defensively to the 1...5 Likert band.
                let value = min(5, max(1, answered ?? 3))
                let recoded = item.keyedPositive ? value : (6 - value)
                raw += Double(recoded)
            }
            // Guard the normalization range (constants are non-zero, but be explicit).
            let span = max(1.0, maxRaw - minRaw)
            let normalized = ((raw - minRaw) / span) * 100.0
            let clamped = min(100, max(0, normalized))
            traitScores.append(TraitScore(trait: trait, score: clamped.rounded()))
        }

        let code = TypeMapper.code(for: traitScores)
        return ScoredResult(traitScores: traitScores, typeCode: code)
    }

    /// Reconstructs a ScoredResult from cached scores (used when loading a saved Profile),
    /// avoiding the need to keep raw responses around for display.
    static func result(fromCached scores: [Trait: Double], typeCode: String) -> ScoredResult {
        let traitScores = Trait.allCases.map { trait in
            TraitScore(trait: trait, score: min(100, max(0, scores[trait] ?? 50)))
        }
        let code = typeCode.isEmpty ? TypeMapper.code(for: traitScores) : typeCode
        return ScoredResult(traitScores: traitScores, typeCode: code)
    }

    /// How many of the bank's items have a valid 1...5 answer.
    static func answeredCount(in responses: [Int: Int]) -> Int {
        ItemBank.items.reduce(0) { acc, item in
            if let v = responses[item.id], (1...5).contains(v) { return acc + 1 }
            return acc
        }
    }

    static func isComplete(_ responses: [Int: Int]) -> Bool {
        answeredCount(in: responses) == ItemBank.count
    }
}
