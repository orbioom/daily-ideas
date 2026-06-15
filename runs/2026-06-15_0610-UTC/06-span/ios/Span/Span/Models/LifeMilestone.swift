import Foundation
import SwiftData

/// A pinned moment in the past, mapped to an exact week on the grid.
@Model
final class LifeMilestone {
    @Attribute(.unique) var id: UUID
    var title: String
    var date: Date
    var symbolName: String
    var colorHex: String
    var note: String?

    init(id: UUID = UUID(),
         title: String,
         date: Date,
         symbolName: String = "star.fill",
         colorHex: String,
         note: String? = nil) {
        self.id = id
        self.title = title
        self.date = date
        self.symbolName = symbolName
        self.colorHex = colorHex
        self.note = note
    }
}
