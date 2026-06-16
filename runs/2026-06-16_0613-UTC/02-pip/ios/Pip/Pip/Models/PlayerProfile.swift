import Foundation
import SwiftData

/// An optional saved player profile to speed up pass-and-play name entry.
@Model
final class PlayerProfile {
    var name: String
    var createdAt: Date
    /// SF Symbol used as the profile's avatar glyph.
    var symbol: String

    init(name: String, createdAt: Date = .now, symbol: String = "person.fill") {
        self.name = name
        self.createdAt = createdAt
        self.symbol = symbol
    }
}
