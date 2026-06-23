import Foundation
import SwiftData
import SwiftUI

/// A project or task bucket that focus sessions can be attached to.
@Model
final class Project {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var iconName: String
    var isArchived: Bool
    var createdAt: Date
    /// Optional daily focus goal in minutes (0 = no goal).
    var dailyGoalMinutes: Int

    @Relationship(deleteRule: .nullify, inverse: \FocusSession.project)
    var sessions: [FocusSession]

    init(id: UUID = UUID(),
         name: String,
         colorHex: String = "7B51B8",
         iconName: String = "target",
         isArchived: Bool = false,
         createdAt: Date = .now,
         dailyGoalMinutes: Int = 0) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.dailyGoalMinutes = dailyGoalMinutes
        self.sessions = []
    }

    var color: Color { Color(hex: colorHex) ?? Theme.Palette.brand }

    /// Total completed focus minutes for this project.
    var totalFocusMinutes: Int {
        sessions.filter { $0.wasCompleted }.reduce(0) { $0 + $1.focusedMinutes }
    }
}
