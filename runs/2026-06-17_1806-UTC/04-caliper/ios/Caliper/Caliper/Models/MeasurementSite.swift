import Foundation
import SwiftData

/// The physical quantity a site measures. Determines canonical storage unit
/// and how values are displayed/converted.
enum UnitKind: String, Codable, CaseIterable {
    case length   // canonical: centimetres
    case mass     // canonical: kilograms
    case percent  // canonical: percent (no conversion)
}

@Model
final class MeasurementSite {
    @Attribute(.unique) var key: String
    var name: String
    var unitKindRaw: String
    var isBuiltIn: Bool
    var goalValue: Double?
    var sortOrder: Int

    init(
        key: String,
        name: String,
        unitKind: UnitKind,
        isBuiltIn: Bool,
        goalValue: Double? = nil,
        sortOrder: Int
    ) {
        self.key = key
        self.name = name
        self.unitKindRaw = unitKind.rawValue
        self.isBuiltIn = isBuiltIn
        self.goalValue = goalValue
        self.sortOrder = sortOrder
    }

    var unitKind: UnitKind {
        UnitKind(rawValue: unitKindRaw) ?? .length
    }
}
