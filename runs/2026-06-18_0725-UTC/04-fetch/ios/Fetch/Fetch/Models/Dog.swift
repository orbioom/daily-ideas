import Foundation
import SwiftData

@Model
final class Dog {
    @Attribute(.unique) var id: UUID
    var name: String
    var breed: String
    var birthdate: Date?
    var photoFilename: String?
    var notes: String
    var isActive: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TrickProgress.dog)
    var progress: [TrickProgress]

    @Relationship(deleteRule: .cascade, inverse: \TrainingSession.dog)
    var sessions: [TrainingSession]

    init(
        id: UUID = UUID(),
        name: String,
        breed: String = "",
        birthdate: Date? = nil,
        photoFilename: String? = nil,
        notes: String = "",
        isActive: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.breed = breed
        self.birthdate = birthdate
        self.photoFilename = photoFilename
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
        self.progress = []
        self.sessions = []
    }
}
