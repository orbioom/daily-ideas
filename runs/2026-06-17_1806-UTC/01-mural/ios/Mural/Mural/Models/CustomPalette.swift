import Foundation
import SwiftData

/// A user-created palette persisted via SwiftData.
@Model
final class CustomPalette {
    @Attribute(.unique) var id: UUID
    var name: String
    var hexes: [String]
    var createdAt: Date

    init(id: UUID = UUID(), name: String, hexes: [String], createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.hexes = hexes
        self.createdAt = createdAt
    }

    /// Bridge to the value-type `Palette` used throughout the UI.
    var asPalette: Palette {
        Palette(id: id.uuidString, name: name, group: .custom, hexes: hexes)
    }
}
