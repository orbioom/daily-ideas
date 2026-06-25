import Foundation
import SwiftData

@Model
final class StudyGoal {
    var id: UUID = UUID()
    var title: String = ""
    var targetMinutesPerWeek: Int = 300
    var isActive: Bool = true
    var createdAt: Date = Date.now
    var notes: String = ""

    init(title: String, targetMinutesPerWeek: Int = 300, isActive: Bool = true, notes: String = "") {
        self.id = UUID()
        self.title = title
        self.targetMinutesPerWeek = targetMinutesPerWeek
        self.isActive = isActive
        self.createdAt = .now
        self.notes = notes
    }
}

@Model
final class AtelierSettings {
    var id: UUID = UUID()
    var showOnboarding: Bool = true
    var hapticsEnabled: Bool = true
    var defaultDurationMinutes: Int = 60
    var defaultMedium: ArtMedium = ArtMedium.pencil
    var weeklyGoalMinutes: Int = 300
    var reminderEnabled: Bool = false
    var reminderHour: Int = 19
    var reminderMinute: Int = 0

    init() { self.id = UUID() }
}
