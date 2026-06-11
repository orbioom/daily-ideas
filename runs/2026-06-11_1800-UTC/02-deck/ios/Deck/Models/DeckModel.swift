import Foundation
import SwiftData

enum CardType: String, Codable, CaseIterable {
    case basic = "Basic"
    case cloze = "Cloze"
}

enum ReviewRating: Int, CaseIterable {
    case again = 0
    case hard  = 1
    case good  = 2
    case easy  = 3

    var label: String {
        switch self {
        case .again: return "Again"
        case .hard:  return "Hard"
        case .good:  return "Good"
        case .easy:  return "Easy"
        }
    }

    var color: String {
        switch self {
        case .again: return "red"
        case .hard:  return "orange"
        case .good:  return "green"
        case .easy:  return "blue"
        }
    }
}

@Model
final class FlashDeck {
    var id: UUID
    var name: String
    var colorHex: String
    var emoji: String
    var createdAt: Date
    var description: String

    @Relationship(deleteRule: .cascade, inverse: \FlashCard.deck)
    var cards: [FlashCard]

    init(name: String, colorHex: String = "#4F8EF7", emoji: String = "📚", description: String = "") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.emoji = emoji
        self.createdAt = Date()
        self.description = description
        self.cards = []
    }

    var dueCount: Int {
        let now = Date()
        return cards.filter { $0.nextReview <= now }.count
    }

    var totalReviewed: Int {
        cards.filter { $0.repetitions > 0 }.count
    }

    var retentionRate: Double {
        let reviewed = cards.filter { !$0.reviews.isEmpty }
        guard !reviewed.isEmpty else { return 0 }
        let correct = reviewed.reduce(0) { sum, card in
            let last = card.reviews.sorted(by: { $0.date < $1.date }).last
            return sum + (last.map { $0.rating >= 2 ? 1 : 0 } ?? 0)
        }
        return Double(correct) / Double(reviewed.count)
    }
}

@Model
final class FlashCard {
    var id: UUID
    var front: String
    var back: String
    var cardTypeRaw: String
    var easeFactor: Double
    var intervalDays: Int
    var repetitions: Int
    var nextReview: Date
    var createdAt: Date

    var deck: FlashDeck?

    @Relationship(deleteRule: .cascade, inverse: \CardReview.card)
    var reviews: [CardReview]

    init(front: String, back: String, cardType: CardType = .basic) {
        self.id = UUID()
        self.front = front
        self.back = back
        self.cardTypeRaw = cardType.rawValue
        self.easeFactor = 2.5
        self.intervalDays = 0
        self.repetitions = 0
        self.nextReview = Date()
        self.createdAt = Date()
        self.reviews = []
    }

    var cardType: CardType {
        CardType(rawValue: cardTypeRaw) ?? .basic
    }

    var isDue: Bool { nextReview <= Date() }

    var clozeDisplayFront: String {
        guard cardType == .cloze else { return front }
        return front.replacingOccurrences(of: #"\{\{(.*?)\}\}"#,
                                          with: "_____",
                                          options: .regularExpression)
    }

    var clozeAnswer: String {
        guard cardType == .cloze else { return back }
        let regex = try? NSRegularExpression(pattern: #"\{\{(.*?)\}\}"#)
        let range = NSRange(front.startIndex..., in: front)
        var answers: [String] = []
        regex?.enumerateMatches(in: front, range: range) { match, _, _ in
            if let match, let r = Range(match.range(at: 1), in: front) {
                answers.append(String(front[r]))
            }
        }
        return answers.joined(separator: "; ")
    }
}

@Model
final class CardReview {
    var date: Date
    var rating: Int
    var intervalDays: Int
    var card: FlashCard?

    init(rating: Int, intervalDays: Int) {
        self.date = Date()
        self.rating = rating
        self.intervalDays = intervalDays
    }
}
