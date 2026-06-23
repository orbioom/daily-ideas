import Foundation
import SwiftData

/// Weight unit preference. Storage is always kg; this only affects display/entry.
enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case kg, lb
    var id: String { rawValue }
    var display: String { rawValue }
}

/// Persisted user preferences. A single row is created on first launch.
@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    var unitRaw: String
    var defaultRestSeconds: Int
    var hapticsEnabled: Bool
    var autoStartRestTimer: Bool
    var barWeightKg: Double
    var trackRPE: Bool

    init(
        id: UUID = UUID(),
        unit: WeightUnit = .kg,
        defaultRestSeconds: Int = 120,
        hapticsEnabled: Bool = true,
        autoStartRestTimer: Bool = true,
        barWeightKg: Double = 20,
        trackRPE: Bool = true
    ) {
        self.id = id
        self.unitRaw = unit.rawValue
        self.defaultRestSeconds = defaultRestSeconds
        self.hapticsEnabled = hapticsEnabled
        self.autoStartRestTimer = autoStartRestTimer
        self.barWeightKg = barWeightKg
        self.trackRPE = trackRPE
    }

    var unit: WeightUnit {
        get { WeightUnit(rawValue: unitRaw) ?? .kg }
        set { unitRaw = newValue.rawValue }
    }
}
