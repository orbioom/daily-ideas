import Foundation
import SwiftData

@Model
final class StudySession {
    var id: UUID
    var date: Date
    var cardTypeRaw: String
    var cardsReviewed: Int
    var correctCount: Int
    var durationSeconds: Int

    var cardType: CardType {
        get { CardType(rawValue: cardTypeRaw) ?? .hiragana }
        set { cardTypeRaw = newValue.rawValue }
    }

    var accuracy: Double {
        guard cardsReviewed > 0 else { return 0.0 }
        return Double(correctCount) / Double(cardsReviewed)
    }

    init(
        id: UUID = UUID(),
        date: Date = Date.now,
        cardType: CardType,
        cardsReviewed: Int,
        correctCount: Int,
        durationSeconds: Int
    ) {
        self.id = id
        self.date = date
        self.cardTypeRaw = cardType.rawValue
        self.cardsReviewed = cardsReviewed
        self.correctCount = correctCount
        self.durationSeconds = durationSeconds
    }
}
