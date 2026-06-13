import Foundation
import SwiftData

/// A favourited quote, stored by its stable library id.
@Model
final class SavedQuote {
    @Attribute(.unique) var quoteID: String
    var savedAt: Date

    init(quoteID: String, savedAt: Date = .now) {
        self.quoteID = quoteID
        self.savedAt = savedAt
    }
}
