import Foundation
import SwiftData

/// A user-authored plan (the Pro builder). Cascades to its sessions and their
/// intervals so deleting a plan cleans up everything beneath it.
@Model
final class CustomPlan {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \CustomSession.plan)
    var sessions: [CustomSession]

    init(id: UUID = UUID(),
         title: String,
         createdAt: Date = Date(),
         sessions: [CustomSession] = []) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.sessions = sessions
    }

    /// Stable plan id used by enrollment & the engine.
    var planRefId: String { "custom-\(id.uuidString)" }

    /// Materialise into the runtime `TrainingPlan` shape used everywhere else.
    /// Each custom session becomes its own "week" so the schedule view can list them.
    func asTrainingPlan() -> TrainingPlan {
        let ordered = sessions.sorted { $0.order < $1.order }
        var weeks: [PlanWeek] = []
        for (i, cs) in ordered.enumerated() {
            let intervals = cs.intervals
                .sorted { $0.order < $1.order }
                .compactMap { ci -> Interval? in
                    guard let kind = IntervalKind(rawValue: ci.kindRaw) else { return nil }
                    return Interval(kind: kind, durationSeconds: ci.durationSeconds)
                }
            // A session must have at least one interval to be runnable.
            guard !intervals.isEmpty else { continue }
            let session = PlanSession(id: "\(planRefId)-w\(i + 1)-s0", intervals: intervals)
            weeks.append(PlanWeek(id: i + 1, focus: cs.title, sessions: [session]))
        }
        return TrainingPlan(
            id: planRefId,
            title: title,
            subtitle: "Your custom plan",
            symbol: "slider.horizontal.3",
            isPro: true,
            weeks: weeks
        )
    }
}

/// One session within a custom plan.
@Model
final class CustomSession {
    @Attribute(.unique) var id: UUID
    var title: String
    var order: Int
    var plan: CustomPlan?
    @Relationship(deleteRule: .cascade, inverse: \CustomInterval.session)
    var intervals: [CustomInterval]

    init(id: UUID = UUID(),
         title: String,
         order: Int,
         plan: CustomPlan? = nil,
         intervals: [CustomInterval] = []) {
        self.id = id
        self.title = title
        self.order = order
        self.plan = plan
        self.intervals = intervals
    }
}

/// One interval within a custom session. Stores the enum as a raw string.
@Model
final class CustomInterval {
    @Attribute(.unique) var id: UUID
    var kindRaw: String
    var durationSeconds: Int
    var order: Int
    var session: CustomSession?

    init(id: UUID = UUID(),
         kind: IntervalKind,
         durationSeconds: Int,
         order: Int,
         session: CustomSession? = nil) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.durationSeconds = max(1, durationSeconds)
        self.order = order
        self.session = session
    }

    var kind: IntervalKind { IntervalKind(rawValue: kindRaw) ?? .run }
}
