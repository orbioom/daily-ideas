import SwiftData
import Foundation

@Model
final class StrokeSettings {
    var id: UUID
    var hasCompletedOnboarding: Bool
    var enableHaptics: Bool
    var displayWatts: Bool
    var weeklyDistanceGoalM: Int
    var weightKg: Double

    init() {
        self.id = UUID()
        self.hasCompletedOnboarding = false
        self.enableHaptics = true
        self.displayWatts = false
        self.weeklyDistanceGoalM = 20000
        self.weightKg = 75
    }

    static func fetch(context: ModelContext) -> StrokeSettings {
        let d = FetchDescriptor<StrokeSettings>()
        if let s = try? context.fetch(d).first { return s }
        let s = StrokeSettings()
        context.insert(s)
        return s
    }
}
