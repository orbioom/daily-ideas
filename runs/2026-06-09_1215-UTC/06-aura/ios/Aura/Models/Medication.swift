import Foundation
import SwiftData

/// A medication in the user's catalog (acute abortive or daily preventive).
/// Built-ins seed on first launch; users add their own.
@Model
final class Medication {
    var name: String
    var typeRaw: String
    var defaultDoseMg: Double
    var isBuiltIn: Bool
    var createdAt: Date

    init(name: String, type: MedType = .acute, defaultDoseMg: Double = 0, isBuiltIn: Bool = false) {
        self.name = name
        self.typeRaw = type.rawValue
        self.defaultDoseMg = max(0, defaultDoseMg)
        self.isBuiltIn = isBuiltIn
        self.createdAt = .now
    }

    var type: MedType {
        get { MedType(rawValue: typeRaw) ?? .acute }
        set { typeRaw = newValue.rawValue }
    }
}
