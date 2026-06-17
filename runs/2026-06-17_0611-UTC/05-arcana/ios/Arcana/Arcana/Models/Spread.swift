import SwiftUI

/// The kinds of readings Arcana offers. Stored by rawValue in SwiftData.
enum SpreadType: String, CaseIterable, Identifiable, Codable {
    case daily = "Card of the Day"
    case threeCard = "Past · Present · Future"
    case yesNo = "Yes / No"
    case relationship = "Relationship"
    case decision = "Decision"
    case celticCross = "Celtic Cross"

    var id: String { rawValue }

    /// Free vs Pro. Core readings stay free; advanced layouts are Pro.
    var isPro: Bool {
        switch self {
        case .daily, .threeCard, .yesNo: return false
        case .relationship, .decision, .celticCross: return true
        }
    }

    var blurb: String {
        switch self {
        case .daily: return "A single card to focus your day."
        case .threeCard: return "A classic line for what was, is, and may come."
        case .yesNo: return "Ask a clear question; let one card answer."
        case .relationship: return "Five cards for the dynamic between two people."
        case .decision: return "Weigh two paths and the heart of the matter."
        case .celticCross: return "The ten-card masterwork for deep, layered insight."
        }
    }

    var icon: String {
        switch self {
        case .daily: return "sun.max"
        case .threeCard: return "rectangle.split.3x1"
        case .yesNo: return "questionmark.circle"
        case .relationship: return "heart.circle"
        case .decision: return "arrow.triangle.branch"
        case .celticCross: return "cross"
        }
    }

    /// The ordered positions for this spread. Each has a short title and the role it plays.
    var positions: [SpreadPosition] {
        switch self {
        case .daily:
            return [SpreadPosition(index: 0, title: "Today", role: "The energy and focus for your day.")]
        case .threeCard:
            return [
                SpreadPosition(index: 0, title: "Past", role: "What has shaped the situation."),
                SpreadPosition(index: 1, title: "Present", role: "Where things stand right now."),
                SpreadPosition(index: 2, title: "Future", role: "Where the current path is leading.")
            ]
        case .yesNo:
            return [SpreadPosition(index: 0, title: "The Answer", role: "A clear yes, no, or maybe to your question.")]
        case .relationship:
            return [
                SpreadPosition(index: 0, title: "You", role: "Your role and energy in the bond."),
                SpreadPosition(index: 1, title: "Them", role: "Their role and energy in the bond."),
                SpreadPosition(index: 2, title: "The Connection", role: "What flows between you."),
                SpreadPosition(index: 3, title: "Challenge", role: "What tests or strains the bond."),
                SpreadPosition(index: 4, title: "Potential", role: "Where the relationship can grow.")
            ]
        case .decision:
            return [
                SpreadPosition(index: 0, title: "The Heart", role: "The core of the matter you're deciding."),
                SpreadPosition(index: 1, title: "Path A", role: "What the first choice brings."),
                SpreadPosition(index: 2, title: "Path B", role: "What the second choice brings."),
                SpreadPosition(index: 3, title: "Guidance", role: "Advice to carry into your decision.")
            ]
        case .celticCross:
            return [
                SpreadPosition(index: 0, title: "Present", role: "The heart of the matter, here and now."),
                SpreadPosition(index: 1, title: "Challenge", role: "What crosses or challenges you."),
                SpreadPosition(index: 2, title: "Foundation", role: "The root and distant past beneath it."),
                SpreadPosition(index: 3, title: "Recent Past", role: "What is just passing away."),
                SpreadPosition(index: 4, title: "Crown", role: "Your goal or what's coming into being."),
                SpreadPosition(index: 5, title: "Near Future", role: "What approaches next."),
                SpreadPosition(index: 6, title: "Self", role: "How you see yourself in this."),
                SpreadPosition(index: 7, title: "Environment", role: "How others and surroundings affect it."),
                SpreadPosition(index: 8, title: "Hopes & Fears", role: "Your inner hopes and fears."),
                SpreadPosition(index: 9, title: "Outcome", role: "Where it all is tending.")
            ]
        }
    }

    var cardCount: Int { positions.count }
}

/// One labeled slot in a spread.
struct SpreadPosition: Identifiable, Hashable {
    let index: Int
    let title: String
    let role: String
    var id: Int { index }
}

/// A single drawn card in a live (not-yet-saved) reading.
struct DrawnResult: Identifiable, Hashable {
    let position: SpreadPosition
    let card: TarotCard
    let reversed: Bool
    var id: Int { position.index }

    /// Position-aware interpretation = the role plus the upright/reversed meaning.
    var interpretation: String {
        reversed ? card.reversed : card.upright
    }

    var orientationLabel: String { reversed ? "Reversed" : "Upright" }
}

/// For the Yes/No spread, the verdict derived from the single card + orientation.
enum YesNoVerdict: String {
    case yes = "Yes"
    case no = "No"
    case maybe = "Maybe"

    var icon: String {
        switch self {
        case .yes: return "checkmark.circle.fill"
        case .no: return "xmark.circle.fill"
        case .maybe: return "minus.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .yes: return Theme.good
        case .no: return Theme.bad
        case .maybe: return Theme.warn
        }
    }

    /// Derive a verdict from a card. Reversed flips a yes/no; "balanced" majors read as maybe.
    static func from(card: TarotCard, reversed: Bool) -> YesNoVerdict {
        // Cards whose energy reads as ambiguous regardless of orientation.
        let maybeIds: Set<Int> = [2, 7, 12, 18, 51] // High Priestess, Chariot, Hanged Man, Moon, Two of Swords
        if maybeIds.contains(card.id) { return .maybe }

        // Base positivity by suit/arcana flavor; reversed inverts.
        let positive = isPositive(card)
        let net = reversed ? !positive : positive
        return net ? .yes : .no
    }

    private static func isPositive(_ card: TarotCard) -> Bool {
        // A grounded heuristic: clearly heavy cards read "no" upright.
        let negativeIds: Set<Int> = [13, 15, 16, // Death, Devil, Tower
                                     52, 54, 57, 58, 59, // 3,5,8,9,10 of Swords
                                     40, 68] // 5 of Cups, 5 of Pentacles
        if negativeIds.contains(card.id) { return false }
        return true
    }
}
