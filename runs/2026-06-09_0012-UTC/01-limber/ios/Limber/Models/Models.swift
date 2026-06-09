import Foundation
import SwiftData

/// A single stretch in the library. Seeded catalog plus user-created customs.
@Model
final class Stretch {
    var name: String
    var areaRaw: String
    var detail: String
    var defaultSeconds: Int
    var bothSides: Bool
    var difficultyRaw: Int   // 1 easy … 3 deep
    var isCustom: Bool
    var createdAt: Date

    init(name: String,
         area: BodyArea,
         detail: String,
         defaultSeconds: Int = 30,
         bothSides: Bool = false,
         difficulty: Int = 1,
         isCustom: Bool = false) {
        self.name = name
        self.areaRaw = area.rawValue
        self.detail = detail
        self.defaultSeconds = max(5, min(defaultSeconds, 600))
        self.bothSides = bothSides
        self.difficultyRaw = min(max(difficulty, 1), 3)
        self.isCustom = isCustom
        self.createdAt = .now
    }

    var area: BodyArea {
        get { BodyArea(rawValue: areaRaw) ?? .fullBody }
        set { areaRaw = newValue.rawValue }
    }

    var difficultyLabel: String {
        switch difficultyRaw {
        case 1: return "Gentle"
        case 2: return "Moderate"
        default: return "Deep"
        }
    }
}

/// An ordered stretch routine. Owns its steps (cascade delete).
@Model
final class Routine {
    var name: String
    var summary: String
    var isFavorite: Bool
    var isBuiltIn: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \RoutineStep.routine)
    var steps: [RoutineStep] = []

    init(name: String, summary: String = "", isBuiltIn: Bool = false) {
        self.name = name
        self.summary = summary
        self.isFavorite = false
        self.isBuiltIn = isBuiltIn
        self.createdAt = .now
    }

    /// Steps in their stored order.
    var orderedSteps: [RoutineStep] {
        steps.sorted { $0.order < $1.order }
    }

    /// Total seconds including both-sides expansion.
    var totalSeconds: Int {
        orderedSteps.reduce(0) { $0 + $1.effectiveSeconds }
    }

    var stretchCount: Int { steps.count }
}

/// One step in a routine: a reference to a stretch with an overriding hold time.
@Model
final class RoutineStep {
    var order: Int
    var seconds: Int
    var stretch: Stretch?
    var routine: Routine?

    init(order: Int, seconds: Int, stretch: Stretch?) {
        self.order = order
        self.seconds = max(5, min(seconds, 600))
        self.stretch = stretch
    }

    var bothSides: Bool { stretch?.bothSides ?? false }

    /// Seconds counting both sides when the stretch is per-side.
    var effectiveSeconds: Int { bothSides ? seconds * 2 : seconds }
}

/// A completed (or partial) practice session, logged for streaks and insights.
@Model
final class SessionLog {
    var date: Date
    var routineName: String
    var seconds: Int
    var stretchesDone: Int
    var completed: Bool
    var feeling: Int        // 0 = unrated, 1…5
    var areasRaw: String    // comma-joined BodyArea raws

    init(date: Date = .now,
         routineName: String,
         seconds: Int,
         stretchesDone: Int,
         completed: Bool,
         feeling: Int = 0,
         areas: [BodyArea] = []) {
        self.date = date
        self.routineName = routineName
        self.seconds = max(0, seconds)
        self.stretchesDone = max(0, stretchesDone)
        self.completed = completed
        self.feeling = min(max(feeling, 0), 5)
        self.areasRaw = areas.map(\.rawValue).joined(separator: ",")
    }

    var minutes: Int { Int((Double(seconds) / 60).rounded()) }

    var areas: [BodyArea] {
        areasRaw.split(separator: ",").compactMap { BodyArea(rawValue: String($0)) }
    }
}
