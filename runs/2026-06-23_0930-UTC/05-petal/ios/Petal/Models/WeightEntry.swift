import Foundation
import SwiftData

/// A single weight measurement. Always stored canonically in kilograms; the UI
/// converts to the user's preferred unit for display.
@Model
final class WeightEntry {
    var id: UUID
    var date: Date
    /// Canonical weight in kilograms.
    var kilograms: Double
    var notes: String
    var createdAt: Date

    var pet: Pet?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        kilograms: Double,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.kilograms = max(0, kilograms)
        self.notes = notes
        self.createdAt = createdAt
    }

    func displayWeight(in unit: WeightUnit) -> Double {
        unit.fromKilograms(kilograms)
    }
}

enum WeightUnit: String, CaseIterable, Identifiable, Codable {
    case kilograms = "kg"
    case pounds = "lb"
    var id: String { rawValue }
    var label: String { rawValue }
    var longLabel: String { self == .kilograms ? "Kilograms (kg)" : "Pounds (lb)" }

    func fromKilograms(_ kg: Double) -> Double {
        switch self {
        case .kilograms: return kg
        case .pounds: return kg * 2.2046226218
        }
    }

    func toKilograms(_ value: Double) -> Double {
        switch self {
        case .kilograms: return value
        case .pounds: return value / 2.2046226218
        }
    }
}
