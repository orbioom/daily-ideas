import Foundation
import SwiftData

@Model
final class Question {
    var id: UUID
    var text: String
    var mode: String      // QuestionMode rawValue
    var category: String  // QuestionCategory rawValue
    var isCustom: Bool
    var isEnabled: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        text: String,
        mode: String,
        category: String,
        isCustom: Bool = false,
        isEnabled: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.text = text
        self.mode = mode
        self.category = category
        self.isCustom = isCustom
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
}

enum QuestionMode: String, CaseIterable, Identifiable {
    case wouldYouRather = "Would You Rather"
    case truthOrDare = "Truth or Dare"
    case neverHaveIEver = "Never Have I Ever"
    case icebreaker = "Icebreaker"

    var id: String { rawValue }
}

enum QuestionCategory: String, CaseIterable, Identifiable {
    case all = "all"
    case family = "family"
    case friends = "friends"
    case couples = "couples"
    case party = "party"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "All"
        case .family: return "Family"
        case .friends: return "Friends"
        case .couples: return "Couples"
        case .party: return "Party"
        }
    }

    var emoji: String {
        switch self {
        case .all: return "🌐"
        case .family: return "👨‍👩‍👧"
        case .friends: return "👥"
        case .couples: return "💑"
        case .party: return "🎉"
        }
    }
}
