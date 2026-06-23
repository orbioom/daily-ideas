import Foundation
import SwiftData

@Model
final class Room {
    @Attribute(.unique) var id: UUID
    var name: String
    var kindRaw: String
    var note: String
    var createdAt: Date

    /// Tasks scoped to this room. Deleting a room nullifies the link so tasks
    /// fall back to "Unassigned" rather than disappearing.
    @Relationship(deleteRule: .nullify, inverse: \MaintenanceTask.room)
    var tasks: [MaintenanceTask]

    @Relationship(deleteRule: .nullify, inverse: \Appliance.room)
    var appliances: [Appliance]

    init(name: String,
         kind: RoomKind,
         note: String = "",
         createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.kindRaw = kind.rawValue
        self.note = note
        self.createdAt = createdAt
        self.tasks = []
        self.appliances = []
    }

    var kind: RoomKind {
        get { RoomKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }
}
