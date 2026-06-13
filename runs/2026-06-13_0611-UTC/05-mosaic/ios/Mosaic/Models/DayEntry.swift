import Foundation
import SwiftData

@Model
final class DayEntry {
    /// Normalized to the start of the day; one entry per calendar day.
    @Attribute(.unique) var day: Date
    var caption: String
    var moodIndex: Int          // 1...5
    var photoFileName: String?  // image lives on disk via ImageStore, never in the store
    var createdAt: Date
    var updatedAt: Date

    init(day: Date, caption: String = "", moodIndex: Int = 3, photoFileName: String? = nil) {
        self.day = Calendar.current.startOfDay(for: day)
        self.caption = caption
        self.moodIndex = moodIndex
        self.photoFileName = photoFileName
        self.createdAt = .now
        self.updatedAt = .now
    }

    var hasPhoto: Bool { photoFileName != nil }
}
