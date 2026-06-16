import Foundation
import SwiftData

/// A saved destination for one-tap round-trip logging (e.g. "Airport — 28 mi").
@Model
final class FavoritePlace {
    var name: String
    /// Canonical one-way distance in MILES.
    var defaultMiles: Double
    var createdAt: Date

    init(name: String, defaultMiles: Double = 0, createdAt: Date = .now) {
        self.name = name
        self.defaultMiles = defaultMiles
        self.createdAt = createdAt
    }
}
