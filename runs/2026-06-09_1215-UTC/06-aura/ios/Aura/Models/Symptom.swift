import Foundation
import SwiftData

/// A symptom experienced during an attack (nausea, light sensitivity…).
/// Built-ins seed on first launch; users add their own.
@Model
final class Symptom {
    var name: String
    var isBuiltIn: Bool
    var createdAt: Date

    /// Inverse of `Attack.symptoms` (many-to-many, nullify on delete).
    @Relationship(inverse: \Attack.symptoms) var attacks: [Attack] = []

    init(name: String, isBuiltIn: Bool = false) {
        self.name = name
        self.isBuiltIn = isBuiltIn
        self.createdAt = .now
    }
}
