import Foundation
import SwiftData

/// One captured moment: a photo + caption + mood + tags for a given day.
/// Multiple moments may share a `dayKey` (Pro feature); the free tier keeps one
/// canonical moment per day.
@Model
final class Moment {
    /// Stable identity used for ShareLink / list IDs.
    @Attribute(.unique) var id: UUID
    /// Canonical `yyyy-MM-dd` key grouping this moment to a calendar day.
    var dayKey: String
    var createdAt: Date
    var title: String
    var caption: String
    var moodRaw: Int
    /// File name (not a path, not a blob) inside the ImageStore. Nil = no photo.
    var imageFilename: String?
    var tags: [String]
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        dayKey: String,
        createdAt: Date = Date(),
        title: String = "",
        caption: String = "",
        mood: Mood = .neutral,
        imageFilename: String? = nil,
        tags: [String] = [],
        isFavorite: Bool = false
    ) {
        self.id = id
        self.dayKey = dayKey
        self.createdAt = createdAt
        self.title = title
        self.caption = caption
        self.moodRaw = mood.rawValue
        self.imageFilename = imageFilename
        self.tags = tags
        self.isFavorite = isFavorite
    }

    var mood: Mood {
        get { Mood.from(moodRaw) }
        set { moodRaw = newValue.rawValue }
    }

    var displayDate: Date {
        DayKey.date(from: dayKey) ?? createdAt
    }
}
