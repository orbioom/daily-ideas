import Foundation
import SwiftData
import SwiftUI

/// The kind of text being memorized. Drives grouping, icons, and accent flavor.
enum PassageCategory: String, CaseIterable, Identifiable, Codable {
    case poem, scripture, speech, lines, vows, quote, other
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .poem:      return "Poem"
        case .scripture: return "Scripture"
        case .speech:    return "Speech"
        case .lines:     return "Lines"
        case .vows:      return "Vows"
        case .quote:     return "Quote"
        case .other:     return "Other"
        }
    }

    var icon: String {
        switch self {
        case .poem:      return "text.book.closed.fill"
        case .scripture: return "book.fill"
        case .speech:    return "megaphone.fill"
        case .lines:     return "theatermasks.fill"
        case .vows:      return "heart.fill"
        case .quote:     return "quote.opening"
        case .other:     return "doc.text.fill"
        }
    }
}

/// A passage the learner is memorizing word-for-word, plus its review history.
@Model
final class Passage {
    var title: String
    var source: String
    var categoryRaw: String
    var fullText: String
    var dateAdded: Date
    var masteryLevel: Int            // 0...5
    var lastReviewed: Date?
    @Relationship(deleteRule: .cascade, inverse: \ReviewLog.passage)
    var reviews: [ReviewLog]

    init(title: String,
         source: String = "",
         category: PassageCategory = .other,
         fullText: String,
         dateAdded: Date = .now,
         masteryLevel: Int = 0,
         lastReviewed: Date? = nil) {
        self.title = title
        self.source = source
        self.categoryRaw = category.rawValue
        self.fullText = fullText
        self.dateAdded = dateAdded
        self.masteryLevel = min(max(masteryLevel, 0), 5)
        self.lastReviewed = lastReviewed
        self.reviews = []
    }

    var category: PassageCategory {
        PassageCategory(rawValue: categoryRaw) ?? .other
    }

    var wordCount: Int { MaskEngine.wordCount(fullText) }

    var readingMinutes: Int { MaskEngine.readingMinutes(fullText) }

    var currentMaskLevel: StudyLevel { StudyLevel.forMastery(masteryLevel) }

    var nextDue: Date {
        SpacedRepetition.nextDue(masteryLevel: masteryLevel, lastReviewed: lastReviewed)
    }

    func isDue(on date: Date = .now) -> Bool {
        SpacedRepetition.isDue(masteryLevel: masteryLevel, lastReviewed: lastReviewed, on: date)
    }

    var isMastered: Bool { masteryLevel >= 5 }
}

/// A single completed study round against a passage.
@Model
final class ReviewLog {
    var date: Date
    var levelIndex: Int       // StudyLevel raw value at time of review
    var score: Double         // 0...1 self-graded
    var passage: Passage?

    init(date: Date = .now, levelIndex: Int, score: Double, passage: Passage? = nil) {
        self.date = date
        self.levelIndex = levelIndex
        self.score = min(max(score, 0), 1)
        self.passage = passage
    }

    var level: StudyLevel { StudyLevel(rawValue: levelIndex) ?? .read }
}
