import Foundation

/// One of the four type dimensions, with its two poles.
struct TypeDimension: Identifiable {
    let title: String
    let highLetter: String   // letter when the source trait is high
    let lowLetter: String    // letter when the source trait is low
    let highLabel: String
    let lowLabel: String
    let sourceTrait: Trait
    var id: String { title }
}

/// The "Identity" suffix derived from Neuroticism (emotional stability).
enum Identity: String {
    case assertive = "Assertive"
    case turbulent = "Turbulent"
    var letter: String { self == .assertive ? "A" : "T" }
    var blurb: String {
        switch self {
        case .assertive: return "Assertive: you tend to feel steady, self-assured, and resistant to stress."
        case .turbulent: return "Turbulent: you tend to feel things deeply and are driven to improve and refine."
        }
    }
}

/// Maps the five Big Five trait scores onto a friendly four-letter type code
/// plus an Assertive/Turbulent identity. This is presented as a friendly summary,
/// not a clinical instrument — see the methodology note in Explore.
///
/// Dimension mapping (each split at the 50 midpoint):
/// - Mind:    Extraversion high → E (Extraverted), low → I (Introverted)
/// - Energy:  Openness high → N (iNtuitive/inventive), low → S (Sensing/grounded)
/// - Nature:  Agreeableness high → F (Feeling), low → T (Thinking)
/// - Tactics: Conscientiousness high → J (Judging/planful), low → P (Prospecting/flexible)
/// - Identity: Neuroticism high → T (Turbulent), low → A (Assertive)
enum TypeMapper {
    static let dimensions: [TypeDimension] = [
        TypeDimension(title: "Mind", highLetter: "E", lowLetter: "I",
                      highLabel: "Extraverted", lowLabel: "Introverted", sourceTrait: .extraversion),
        TypeDimension(title: "Energy", highLetter: "N", lowLetter: "S",
                      highLabel: "Intuitive", lowLabel: "Observant", sourceTrait: .openness),
        TypeDimension(title: "Nature", highLetter: "F", lowLetter: "T",
                      highLabel: "Feeling", lowLabel: "Thinking", sourceTrait: .agreeableness),
        TypeDimension(title: "Tactics", highLetter: "J", lowLetter: "P",
                      highLabel: "Judging", lowLabel: "Prospecting", sourceTrait: .conscientiousness)
    ]

    /// Builds the four-letter code (e.g. "INFJ") from scored traits.
    static func code(for traitScores: [TraitScore]) -> String {
        func score(_ trait: Trait) -> Double {
            traitScores.first { $0.trait == trait }?.score ?? 50
        }
        return dimensions.map { dim in
            score(dim.sourceTrait) >= 50 ? dim.highLetter : dim.lowLetter
        }.joined()
    }

    static func identity(for traitScores: [TraitScore]) -> Identity {
        let n = traitScores.first { $0.trait == .neuroticism }?.score ?? 50
        return n >= 50 ? .turbulent : .assertive
    }

    /// The chosen letter for a dimension given a result, plus whether it's the high pole.
    static func resolved(_ dim: TypeDimension, in result: ScoredResult) -> (letter: String, label: String, isHigh: Bool) {
        let isHigh = result.score(for: dim.sourceTrait) >= 50
        return (isHigh ? dim.highLetter : dim.lowLetter,
                isHigh ? dim.highLabel : dim.lowLabel,
                isHigh)
    }
}
