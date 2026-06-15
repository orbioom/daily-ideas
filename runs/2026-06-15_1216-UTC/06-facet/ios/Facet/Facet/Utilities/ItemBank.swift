import Foundation

/// The Big Five (OCEAN) personality traits.
enum Trait: String, CaseIterable, Identifiable, Codable {
    case openness = "Openness"
    case conscientiousness = "Conscientiousness"
    case extraversion = "Extraversion"
    case agreeableness = "Agreeableness"
    case neuroticism = "Neuroticism"

    var id: String { rawValue }

    /// Short label used in compact charts.
    var shortLabel: String {
        switch self {
        case .openness: return "O"
        case .conscientiousness: return "C"
        case .extraversion: return "E"
        case .agreeableness: return "A"
        case .neuroticism: return "N"
        }
    }

    var symbolName: String {
        switch self {
        case .openness: return "sparkles"
        case .conscientiousness: return "checklist"
        case .extraversion: return "person.2.wave.2.fill"
        case .agreeableness: return "heart.fill"
        case .neuroticism: return "wind"
        }
    }

    /// A friendly, research-grounded summary of what the trait measures.
    var summary: String {
        switch self {
        case .openness:
            return "Openness to Experience reflects curiosity, imagination, and a taste for variety and new ideas. High scorers are inventive and exploratory; lower scorers prefer the familiar and practical."
        case .conscientiousness:
            return "Conscientiousness captures organization, dependability, and self-discipline. High scorers are planful and goal-driven; lower scorers are more flexible, spontaneous, and easygoing."
        case .extraversion:
            return "Extraversion describes how much you draw energy from the outer, social world. High scorers are outgoing and energized by people; lower scorers are reserved and recharge in quieter settings."
        case .agreeableness:
            return "Agreeableness reflects warmth, cooperation, and compassion toward others. High scorers are trusting and considerate; lower scorers are more skeptical, competitive, and direct."
        case .neuroticism:
            return "Neuroticism (the inverse of emotional stability) measures sensitivity to stress and negative emotion. High scorers feel things intensely and worry more; lower scorers stay calm and even-keeled."
        }
    }

    /// The lower-pole description (used for the type/identity framing).
    var lowPole: String {
        switch self {
        case .openness: return "Grounded"
        case .conscientiousness: return "Spontaneous"
        case .extraversion: return "Reserved"
        case .agreeableness: return "Frank"
        case .neuroticism: return "Steady"
        }
    }

    var highPole: String {
        switch self {
        case .openness: return "Inventive"
        case .conscientiousness: return "Diligent"
        case .extraversion: return "Outgoing"
        case .agreeableness: return "Warm"
        case .neuroticism: return "Sensitive"
        }
    }
}

/// A single questionnaire item drawn from the public-domain IPIP pool.
/// `keyedPositive == false` means the item is reverse-scored (6 − response).
struct Item: Identifiable, Hashable {
    let id: Int
    let text: String
    let trait: Trait
    let keyedPositive: Bool
}

/// The full item bank: 40 public-domain IPIP Big Five markers, 8 per trait,
/// a mix of positively and reverse-keyed items. These items are in the public domain
/// (International Personality Item Pool, ipip.ori.org).
enum ItemBank {
    static let items: [Item] = [
        // MARK: - Openness (8)
        Item(id: 1,  text: "I have a vivid imagination.", trait: .openness, keyedPositive: true),
        Item(id: 2,  text: "I am full of ideas.", trait: .openness, keyedPositive: true),
        Item(id: 3,  text: "I enjoy thinking about abstract ideas.", trait: .openness, keyedPositive: true),
        Item(id: 4,  text: "I am quick to understand new concepts.", trait: .openness, keyedPositive: true),
        Item(id: 5,  text: "I am not interested in abstract ideas.", trait: .openness, keyedPositive: false),
        Item(id: 6,  text: "I have difficulty understanding abstract ideas.", trait: .openness, keyedPositive: false),
        Item(id: 7,  text: "I do not have a good imagination.", trait: .openness, keyedPositive: false),
        Item(id: 8,  text: "I avoid difficult reading material.", trait: .openness, keyedPositive: false),

        // MARK: - Conscientiousness (8)
        Item(id: 9,  text: "I get chores done right away.", trait: .conscientiousness, keyedPositive: true),
        Item(id: 10, text: "I like order and keep things tidy.", trait: .conscientiousness, keyedPositive: true),
        Item(id: 11, text: "I follow a schedule and stick to my plans.", trait: .conscientiousness, keyedPositive: true),
        Item(id: 12, text: "I pay attention to details.", trait: .conscientiousness, keyedPositive: true),
        Item(id: 13, text: "I often forget to put things back in their proper place.", trait: .conscientiousness, keyedPositive: false),
        Item(id: 14, text: "I leave my belongings around.", trait: .conscientiousness, keyedPositive: false),
        Item(id: 15, text: "I make a mess of things.", trait: .conscientiousness, keyedPositive: false),
        Item(id: 16, text: "I shirk my duties.", trait: .conscientiousness, keyedPositive: false),

        // MARK: - Extraversion (8)
        Item(id: 17, text: "I am the life of the party.", trait: .extraversion, keyedPositive: true),
        Item(id: 18, text: "I feel comfortable around people.", trait: .extraversion, keyedPositive: true),
        Item(id: 19, text: "I start conversations.", trait: .extraversion, keyedPositive: true),
        Item(id: 20, text: "I talk to a lot of different people at parties.", trait: .extraversion, keyedPositive: true),
        Item(id: 21, text: "I don't talk a lot.", trait: .extraversion, keyedPositive: false),
        Item(id: 22, text: "I keep in the background.", trait: .extraversion, keyedPositive: false),
        Item(id: 23, text: "I have little to say.", trait: .extraversion, keyedPositive: false),
        Item(id: 24, text: "I find it difficult to approach others.", trait: .extraversion, keyedPositive: false),

        // MARK: - Agreeableness (8)
        Item(id: 25, text: "I sympathize with others' feelings.", trait: .agreeableness, keyedPositive: true),
        Item(id: 26, text: "I take time out for others.", trait: .agreeableness, keyedPositive: true),
        Item(id: 27, text: "I feel others' emotions.", trait: .agreeableness, keyedPositive: true),
        Item(id: 28, text: "I make people feel at ease.", trait: .agreeableness, keyedPositive: true),
        Item(id: 29, text: "I am not really interested in others.", trait: .agreeableness, keyedPositive: false),
        Item(id: 30, text: "I insult people.", trait: .agreeableness, keyedPositive: false),
        Item(id: 31, text: "I am not interested in other people's problems.", trait: .agreeableness, keyedPositive: false),
        Item(id: 32, text: "I feel little concern for others.", trait: .agreeableness, keyedPositive: false),

        // MARK: - Neuroticism (8)
        Item(id: 33, text: "I get stressed out easily.", trait: .neuroticism, keyedPositive: true),
        Item(id: 34, text: "I worry about things.", trait: .neuroticism, keyedPositive: true),
        Item(id: 35, text: "I am easily disturbed.", trait: .neuroticism, keyedPositive: true),
        Item(id: 36, text: "I change my mood a lot.", trait: .neuroticism, keyedPositive: true),
        Item(id: 37, text: "I am relaxed most of the time.", trait: .neuroticism, keyedPositive: false),
        Item(id: 38, text: "I seldom feel blue.", trait: .neuroticism, keyedPositive: false),
        Item(id: 39, text: "I rarely get irritated.", trait: .neuroticism, keyedPositive: false),
        Item(id: 40, text: "I remain calm under pressure.", trait: .neuroticism, keyedPositive: false)
    ]

    static var count: Int { items.count }

    /// Stable, deterministic order: items grouped by trait already in declaration order.
    /// We interleave so the test doesn't feel like five blocks of the same theme.
    static let ordered: [Item] = {
        let byTrait = Dictionary(grouping: items, by: { $0.trait })
        var result: [Item] = []
        let traits = Trait.allCases
        // 8 items per trait → 8 rounds of one item per trait.
        for round in 0..<8 {
            for trait in traits {
                if let group = byTrait[trait], round < group.count {
                    result.append(group[round])
                }
            }
        }
        // Safety: if any item was missed (shouldn't happen), append remaining.
        if result.count != items.count {
            let included = Set(result.map { $0.id })
            result.append(contentsOf: items.filter { !included.contains($0.id) })
        }
        return result
    }()

    static func item(id: Int) -> Item? {
        items.first { $0.id == id }
    }
}
