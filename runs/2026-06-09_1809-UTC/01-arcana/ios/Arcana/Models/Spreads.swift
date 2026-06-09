import Foundation

/// A single position within a spread: where the card lands and what it speaks to.
struct SpreadPosition: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let prompt: String
}

/// A static tarot spread definition — its name, a short blurb, and the ordered
/// positions to draw. This is reference data, not SwiftData.
struct Spread: Identifiable, Hashable {
    let id: String
    let name: String
    let blurb: String
    let symbol: String
    let positions: [SpreadPosition]

    var cardCount: Int { positions.count }
}

enum SpreadCatalog {
    static func spread(named name: String) -> Spread? {
        all.first { $0.name == name }
    }

    static let all: [Spread] = [
        Spread(
            id: "single",
            name: "Single Card",
            blurb: "One card for clarity, focus, or a daily touchstone.",
            symbol: "rectangle.portrait",
            positions: [
                SpreadPosition(title: "Your Card", prompt: "The energy or guidance for right now.")
            ]
        ),
        Spread(
            id: "ppf",
            name: "Past · Present · Future",
            blurb: "A timeless three-card arc to trace how a situation is moving.",
            symbol: "arrow.right",
            positions: [
                SpreadPosition(title: "Past", prompt: "What led you here."),
                SpreadPosition(title: "Present", prompt: "Where things stand now."),
                SpreadPosition(title: "Future", prompt: "Where the current path leads.")
            ]
        ),
        Spread(
            id: "sao",
            name: "Situation · Action · Outcome",
            blurb: "A practical three-card read for a decision or next step.",
            symbol: "list.number",
            positions: [
                SpreadPosition(title: "Situation", prompt: "The heart of what you face."),
                SpreadPosition(title: "Action", prompt: "What to do or embody."),
                SpreadPosition(title: "Outcome", prompt: "The likely result of that action.")
            ]
        ),
        Spread(
            id: "relationship",
            name: "Relationship",
            blurb: "Five cards to illuminate the dynamic between you and another.",
            symbol: "heart.text.square",
            positions: [
                SpreadPosition(title: "You", prompt: "Your role and energy in the bond."),
                SpreadPosition(title: "Them", prompt: "Their role and energy in the bond."),
                SpreadPosition(title: "Connection", prompt: "What links you together."),
                SpreadPosition(title: "Challenge", prompt: "The tension to work through."),
                SpreadPosition(title: "Potential", prompt: "Where the relationship can grow.")
            ]
        ),
        Spread(
            id: "celtic",
            name: "Celtic Cross",
            blurb: "The classic ten-card deep dive into a question's full landscape.",
            symbol: "plus.viewfinder",
            positions: [
                SpreadPosition(title: "The Present", prompt: "The heart of the matter now."),
                SpreadPosition(title: "The Challenge", prompt: "What crosses or complicates it."),
                SpreadPosition(title: "The Past", prompt: "The roots and recent history."),
                SpreadPosition(title: "The Future", prompt: "What is approaching."),
                SpreadPosition(title: "Above", prompt: "Your goal or conscious aim."),
                SpreadPosition(title: "Below", prompt: "Subconscious forces at play."),
                SpreadPosition(title: "Advice", prompt: "How best to approach this."),
                SpreadPosition(title: "External", prompt: "People and environment around you."),
                SpreadPosition(title: "Hopes & Fears", prompt: "What you most hope for or dread."),
                SpreadPosition(title: "Outcome", prompt: "Where it all culminates.")
            ]
        )
    ]
}
