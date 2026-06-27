import SwiftData
import Foundation

@Model
final class AmpSettings {
    var id: UUID
    var useImperial: Bool
    var currencySymbol: String
    var fuelCostPerUnit: Double
    var fuelUnitLabel: String
    var enableHaptics: Bool
    var hasCompletedOnboarding: Bool
    var defaultVehicleID: UUID?

    init() {
        self.id = UUID()
        self.useImperial = Locale.current.measurementSystem == .us
        self.currencySymbol = "$"
        self.fuelCostPerUnit = 3.80
        self.fuelUnitLabel = "gal"
        self.enableHaptics = true
        self.hasCompletedOnboarding = false
        self.defaultVehicleID = nil
    }

    static func fetch(context: ModelContext) -> AmpSettings {
        let descriptor = FetchDescriptor<AmpSettings>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let settings = AmpSettings()
        context.insert(settings)
        return settings
    }
}
