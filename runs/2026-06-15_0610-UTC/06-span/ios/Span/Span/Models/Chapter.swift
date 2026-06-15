import Foundation
import SwiftData

/// A colored life era spanning a date range. `endDate == nil` means ongoing.
@Model
final class Chapter {
    @Attribute(.unique) var id: UUID
    var title: String
    var startDate: Date
    var endDate: Date?
    var colorHex: String
    var note: String?
    var sortOrder: Int

    init(id: UUID = UUID(),
         title: String,
         startDate: Date,
         endDate: Date? = nil,
         colorHex: String,
         note: String? = nil,
         sortOrder: Int = 0) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.colorHex = colorHex
        self.note = note
        self.sortOrder = sortOrder
    }
}
