import Foundation
import SwiftData

/// A physical location in the home that holds items. Deleting a room does NOT
/// delete its items — their `room` is set to nil (nullify) so they fall into the
/// "Unassigned" bucket rather than vanishing from the inventory.
@Model
final class Room {
    var name: String
    var iconName: String
    var notes: String
    var sortIndex: Int
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Item.room)
    var items: [Item] = []

    init(name: String,
         iconName: String = "square.split.bottomrightquarter",
         notes: String = "",
         sortIndex: Int = 0,
         createdAt: Date = .now) {
        self.name = name
        self.iconName = iconName
        self.notes = notes
        self.sortIndex = sortIndex
        self.createdAt = createdAt
    }
}

extension Room {
    /// A curated set of room-appropriate SF Symbols for the icon picker.
    static let iconChoices: [String] = [
        "sofa.fill",
        "bed.double.fill",
        "fork.knife",
        "shower.fill",
        "car.fill",
        "books.vertical.fill",
        "tv.fill",
        "washer.fill",
        "tent.fill",
        "building.columns.fill",
        "square.split.bottomrightquarter",
        "archivebox.fill"
    ]
}
