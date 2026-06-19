import Foundation
import SwiftData

@Model
final class StoryEntry {
    var id: UUID
    var title: String
    var bodyText: String
    var promptText: String
    var eraRaw: String
    var moodRaw: String
    var createdDate: Date
    var modifiedDate: Date
    var isFavorite: Bool
    var tagsRaw: String

    init(
        id: UUID = UUID(),
        title: String = "",
        bodyText: String = "",
        promptText: String = "",
        era: LifeEra = .reflection,
        mood: EntryMood = .reflective,
        createdDate: Date = Date(),
        modifiedDate: Date = Date(),
        isFavorite: Bool = false,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.bodyText = bodyText
        self.promptText = promptText
        self.eraRaw = era.rawValue
        self.moodRaw = mood.rawValue
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.isFavorite = isFavorite
        self.tagsRaw = tags.joined(separator: ",")
    }

    var era: LifeEra {
        get { LifeEra(rawValue: eraRaw) ?? .reflection }
        set { eraRaw = newValue.rawValue }
    }

    var mood: EntryMood {
        get { EntryMood(rawValue: moodRaw) ?? .reflective }
        set { moodRaw = newValue.rawValue }
    }

    var wordCount: Int {
        let trimmed = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        return trimmed.split(separator: " ").count
    }

    var tags: [String] {
        get {
            tagsRaw.isEmpty ? [] : tagsRaw.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        }
        set {
            tagsRaw = newValue.joined(separator: ",")
        }
    }
}
