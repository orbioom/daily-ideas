import Foundation
import SwiftData

enum CardType: String, CaseIterable, Codable {
    case hiragana = "hiragana"
    case katakana = "katakana"
    case kanji = "kanji"

    var displayName: String {
        switch self {
        case .hiragana: return "Hiragana"
        case .katakana: return "Katakana"
        case .kanji: return "Kanji"
        }
    }
}

@Model
final class KanaCard {
    var id: UUID
    var character: String
    var romaji: String
    var meaning: String
    var cardTypeRaw: String
    var srsInterval: Int
    var srsEaseFactor: Double
    var srsDueDate: Date
    var totalReviews: Int
    var correctReviews: Int
    var lastReviewDate: Date?
    var isLearned: Bool

    var cardType: CardType {
        get { CardType(rawValue: cardTypeRaw) ?? .hiragana }
        set { cardTypeRaw = newValue.rawValue }
    }

    var accuracy: Double {
        guard totalReviews > 0 else { return 0.0 }
        return Double(correctReviews) / Double(totalReviews)
    }

    var isDue: Bool {
        Date.now >= srsDueDate
    }

    init(
        id: UUID = UUID(),
        character: String,
        romaji: String,
        meaning: String = "",
        cardType: CardType,
        srsInterval: Int = 1,
        srsEaseFactor: Double = 2.5,
        srsDueDate: Date = Date.now,
        totalReviews: Int = 0,
        correctReviews: Int = 0,
        lastReviewDate: Date? = nil,
        isLearned: Bool = false
    ) {
        self.id = id
        self.character = character
        self.romaji = romaji
        self.meaning = meaning
        self.cardTypeRaw = cardType.rawValue
        self.srsInterval = srsInterval
        self.srsEaseFactor = srsEaseFactor
        self.srsDueDate = srsDueDate
        self.totalReviews = totalReviews
        self.correctReviews = correctReviews
        self.lastReviewDate = lastReviewDate
        self.isLearned = isLearned
    }

    func review(correct: Bool) {
        totalReviews += 1
        lastReviewDate = Date.now

        if correct {
            correctReviews += 1
            let newInterval = max(1, Int(Double(srsInterval) * srsEaseFactor))
            srsInterval = newInterval
            srsEaseFactor = min(srsEaseFactor + 0.1, 4.0)
        } else {
            srsInterval = 1
            srsEaseFactor = max(1.3, srsEaseFactor - 0.2)
        }

        srsDueDate = Date.now.addingTimeInterval(Double(srsInterval) * 86400)
        isLearned = srsInterval >= 21
    }
}
