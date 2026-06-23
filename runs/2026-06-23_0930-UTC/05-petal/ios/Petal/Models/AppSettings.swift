import Foundation
import SwiftData

/// Singleton-style persisted settings model. Exactly one row is maintained.
@Model
final class AppSettings {
    var id: UUID
    var hasOnboarded: Bool
    var hapticsEnabled: Bool
    var preferredWeightUnitRaw: String
    /// How many days ahead an item counts as "Soon" in the care timeline.
    var soonWindowDays: Int
    var ownerName: String
    var appearanceRaw: String

    init(
        id: UUID = UUID(),
        hasOnboarded: Bool = false,
        hapticsEnabled: Bool = true,
        preferredWeightUnit: WeightUnit = .kilograms,
        soonWindowDays: Int = 7,
        ownerName: String = "",
        appearance: AppearanceMode = .system
    ) {
        self.id = id
        self.hasOnboarded = hasOnboarded
        self.hapticsEnabled = hapticsEnabled
        self.preferredWeightUnitRaw = preferredWeightUnit.rawValue
        self.soonWindowDays = soonWindowDays
        self.ownerName = ownerName
        self.appearanceRaw = appearance.rawValue
    }

    var preferredWeightUnit: WeightUnit {
        get { WeightUnit(rawValue: preferredWeightUnitRaw) ?? .kilograms }
        set { preferredWeightUnitRaw = newValue.rawValue }
    }

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable, Codable {
    case system, light, dark
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}
