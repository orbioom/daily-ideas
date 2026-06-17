import Foundation
import SwiftData

/// A structured training program made of ordered days.
@Model
final class Program {
    @Attribute(.unique) var id: UUID
    var name: String
    /// Stored raw; access via `type`.
    var typeRaw: String
    var notes: String
    var isActive: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ProgramDay.program)
    var days: [ProgramDay]

    init(name: String,
         type: ProgramType,
         notes: String = "",
         isActive: Bool = false,
         createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.typeRaw = type.rawValue
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
        self.days = []
    }

    var type: ProgramType {
        get { ProgramType(rawValue: typeRaw) ?? .custom }
        set { typeRaw = newValue.rawValue }
    }

    /// Days in their authored order.
    var orderedDays: [ProgramDay] {
        days.sorted { $0.order < $1.order }
    }
}
