import Foundation
import SwiftData

/// A single journal entry. Rich enough for daily reflection: a moment in time,
/// optional title, free body text, a 1–5 mood, and many-to-many tags.
@Model
final class JournalEntry {
    var id: UUID
    var date: Date                 // the moment the entry is *about*
    var title: String
    var body: String
    var mood: Int                  // 0 = unset, 1…5 = very low → very good
    var pinned: Bool
    var favorite: Bool
    var promptText: String         // the prompt this answered, "" if free-form
    var createdAt: Date
    var modifiedAt: Date

    @Relationship(inverse: \Tag.entries)
    var tags: [Tag] = []

    init(
        id: UUID = UUID(),
        date: Date = .now,
        title: String = "",
        body: String = "",
        mood: Int = 0,
        pinned: Bool = false,
        favorite: Bool = false,
        promptText: String = "",
        createdAt: Date = .now,
        modifiedAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.body = body
        self.mood = mood
        self.pinned = pinned
        self.favorite = favorite
        self.promptText = promptText
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    /// Word count derived from the body, clamped and crash-safe.
    var wordCount: Int {
        body.split { $0 == " " || $0 == "\n" || $0 == "\t" }.count
    }

    var displayTitle: String {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { return t }
        let firstLine = body.split(separator: "\n").first.map(String.init) ?? ""
        let trimmed = firstLine.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "Untitled" : String(trimmed.prefix(60))
    }

    var preview: String {
        let clean = body.replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespaces)
        return String(clean.prefix(140))
    }
}

enum Mood: Int, CaseIterable, Identifiable {
    case veryLow = 1, low, neutral, good, veryGood
    var id: Int { rawValue }

    var label: String {
        switch self {
        case .veryLow:  return "Rough"
        case .low:      return "Low"
        case .neutral:  return "Okay"
        case .good:     return "Good"
        case .veryGood: return "Great"
        }
    }

    var symbol: String {
        switch self {
        case .veryLow:  return "cloud.rain.fill"
        case .low:      return "cloud.fill"
        case .neutral:  return "cloud.sun.fill"
        case .good:     return "sun.max.fill"
        case .veryGood: return "sparkles"
        }
    }

    /// Hue ramp from muted blue (low) to warm green (high), on-brand & calm.
    var colorHex: UInt32 {
        switch self {
        case .veryLow:  return 0x6E7BA6
        case .low:      return 0x6E92A6
        case .neutral:  return 0x7CA68F
        case .good:     return 0x5FA37C
        case .veryGood: return 0x3E9E78
        }
    }
}
