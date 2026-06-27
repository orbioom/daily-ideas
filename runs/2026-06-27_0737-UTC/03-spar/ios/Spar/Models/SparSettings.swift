import SwiftData
import Foundation

@Model
final class SparSettings {
    var id: UUID
    var hasCompletedOnboarding: Bool
    var enableHaptics: Bool
    var defaultRoundDurationSeconds: Int
    var weeklyTrainingGoalMinutes: Int
    var defaultDisciplineRaw: String

    init() {
        self.id = UUID()
        self.hasCompletedOnboarding = false
        self.enableHaptics = true
        self.defaultRoundDurationSeconds = 180
        self.weeklyTrainingGoalMinutes = 300
        self.defaultDisciplineRaw = Discipline.boxing.rawValue
    }

    var defaultDiscipline: Discipline {
        get { Discipline(rawValue: defaultDisciplineRaw) ?? .boxing }
        set { defaultDisciplineRaw = newValue.rawValue }
    }

    static func fetch(context: ModelContext) -> SparSettings {
        let d = FetchDescriptor<SparSettings>()
        if let s = try? context.fetch(d).first { return s }
        let s = SparSettings()
        context.insert(s)
        return s
    }
}
