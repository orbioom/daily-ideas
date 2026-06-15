import Foundation
import SwiftData

/// A future moment to count down to.
@Model
final class FutureGoal {
    @Attribute(.unique) var id: UUID
    var title: String
    var targetDate: Date
    var note: String?
    var colorHex: String

    init(id: UUID = UUID(),
         title: String,
         targetDate: Date,
         note: String? = nil,
         colorHex: String) {
        self.id = id
        self.title = title
        self.targetDate = targetDate
        self.note = note
        self.colorHex = colorHex
    }
}
