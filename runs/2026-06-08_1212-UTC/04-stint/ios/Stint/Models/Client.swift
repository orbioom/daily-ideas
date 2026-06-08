import Foundation
import SwiftData

@Model
final class Client {
    var id: UUID
    var name: String
    var colorHex: UInt32
    var hourlyRate: Double      // default rate for projects under this client
    var archived: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Project.client)
    var projects: [Project] = []

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: UInt32 = 0x3E8E7E,
        hourlyRate: Double = 0,
        archived: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.hourlyRate = max(0, hourlyRate)
        self.archived = archived
        self.createdAt = createdAt
    }
}
