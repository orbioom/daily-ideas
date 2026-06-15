import Foundation

/// Per-trait commentary in a compatibility read.
struct TraitCompatibility: Identifiable {
    let trait: Trait
    let scoreA: Double
    let scoreB: Double
    /// 0–100 similarity for this trait.
    let similarity: Double
    let note: String
    var id: String { trait.rawValue }
    /// True when the difference is large enough to be "complementary" rather than "aligned".
    var isComplementary: Bool { abs(scoreA - scoreB) >= 35 }
}

/// The overall compatibility result between two profiles.
struct CompatibilityResult {
    let nameA: String
    let nameB: String
    /// Overall 0–100.
    let overall: Double
    let perTrait: [TraitCompatibility]
    let headline: String
    let summary: String

    var band: String {
        switch overall {
        case ..<45: return "Contrasting"
        case 45..<65: return "Balanced"
        case 65..<82: return "Harmonious"
        default: return "Deeply aligned"
        }
    }
}

/// Pure compatibility computation between two scored results.
///
/// For each trait we compute similarity = 100 − |a − b| (so identical = 100).
/// Overall is a weighted blend: Agreeableness and Neuroticism alignment matter most for
/// day-to-day harmony, so they're weighted slightly higher. All divisions are guarded.
enum CompatibilityEngine {
    private static let weights: [Trait: Double] = [
        .openness: 0.8,
        .conscientiousness: 0.9,
        .extraversion: 0.8,
        .agreeableness: 1.3,
        .neuroticism: 1.2
    ]

    static func compatibility(_ a: ScoredResult, nameA: String,
                              _ b: ScoredResult, nameB: String) -> CompatibilityResult {
        var perTrait: [TraitCompatibility] = []
        var weightedSum = 0.0
        var totalWeight = 0.0

        for trait in Trait.allCases {
            let sa = a.score(for: trait)
            let sb = b.score(for: trait)
            let similarity = max(0, 100 - abs(sa - sb))
            let w = weights[trait] ?? 1.0
            weightedSum += similarity * w
            totalWeight += w
            perTrait.append(TraitCompatibility(
                trait: trait,
                scoreA: sa,
                scoreB: sb,
                similarity: similarity,
                note: note(for: trait, sa: sa, sb: sb, nameA: nameA, nameB: nameB)
            ))
        }

        // Guard the division — totalWeight is always > 0 here, but stay explicit.
        let overall = totalWeight > 0 ? (weightedSum / totalWeight) : 50
        let rounded = overall.rounded()

        return CompatibilityResult(
            nameA: nameA,
            nameB: nameB,
            overall: rounded,
            perTrait: perTrait,
            headline: headline(for: rounded),
            summary: summary(for: rounded, nameA: nameA, nameB: nameB)
        )
    }

    private static func headline(for overall: Double) -> String {
        switch overall {
        case ..<45: return "Opposites that can teach each other"
        case 45..<65: return "A balanced match with room to grow"
        case 65..<82: return "Naturally harmonious"
        default: return "Remarkably in sync"
        }
    }

    private static func summary(for overall: Double, nameA: String, nameB: String) -> String {
        switch overall {
        case ..<45:
            return "\(nameA) and \(nameB) approach the world quite differently. That contrast can be a source of friction — or of real growth, if both stay curious about the other's perspective."
        case 45..<65:
            return "\(nameA) and \(nameB) share some core tendencies while differing on others. With communication, the differences become complementary strengths rather than sticking points."
        case 65..<82:
            return "\(nameA) and \(nameB) align on most of what matters day to day. You're likely to find an easy rhythm together while still bringing distinct perspectives."
        default:
            return "\(nameA) and \(nameB) are strikingly similar across the board. You'll likely understand each other instinctively — just watch that you challenge each other now and then."
        }
    }

    private static func note(for trait: Trait, sa: Double, sb: Double, nameA: String, nameB: String) -> String {
        let diff = abs(sa - sb)
        let bandA = TraitBand.from(score: sa)
        let bandB = TraitBand.from(score: sb)

        if diff < 18 {
            // Aligned
            switch trait {
            case .openness: return "Similar appetite for new ideas and experiences — you'll explore (or stay grounded) together comfortably."
            case .conscientiousness: return "A shared approach to structure and planning means fewer clashes over tidiness, schedules, and follow-through."
            case .extraversion: return "Matched social energy — you'll likely agree on how much time to spend out versus recharging at home."
            case .agreeableness: return "You meet conflict and cooperation in much the same way, which makes everyday harmony easier."
            case .neuroticism: return "You handle stress and emotion at a similar intensity, so you'll often be on the same wavelength when things get hard."
            }
        } else if diff >= 35 {
            // Complementary / potential friction
            let higher = sa >= sb ? nameA : nameB
            let lower = sa >= sb ? nameB : nameA
            switch trait {
            case .openness: return "\(higher) craves novelty while \(lower) prefers the familiar — name this early so it stays exciting rather than frustrating."
            case .conscientiousness: return "\(higher) leans planful while \(lower) is more spontaneous; agreeing on which decisions need a plan keeps the peace."
            case .extraversion: return "\(higher) is energized by people while \(lower) recharges in quiet — respecting each other's social battery matters."
            case .agreeableness: return "\(higher) prioritizes harmony while \(lower) is more frank; honest, kind communication bridges the gap."
            case .neuroticism: return "\(higher) feels stress more intensely than \(lower); patience and reassurance go a long way here."
            }
        } else {
            // Moderate difference
            return "\(nameA) (\(bandA.rawValue.lowercased())) and \(nameB) (\(bandB.rawValue.lowercased())) differ a little here — a gentle, complementary contrast."
        }
    }
}
