import Foundation
import SwiftData

/// A favourited sky object (star / planet / Moon), persisted across launches.
@Model
final class FavoriteObject {
    /// Object identifier matching SkyObject.id (e.g. "star.53" or "body.Mars").
    @Attribute(.unique) var identifier: String
    var name: String
    var kindRaw: String
    var addedAt: Date

    init(identifier: String, name: String, kindRaw: String, addedAt: Date = .now) {
        self.identifier = identifier
        self.name = name
        self.kindRaw = kindRaw
        self.addedAt = addedAt
    }
}
