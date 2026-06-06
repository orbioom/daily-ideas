import Foundation
import SwiftData

/// A climbing session: a dated outing at a location, owning an ordered list of
/// attempts. Duration is stored in minutes.
@Model
final class Session {
    var id: UUID
    var date: Date
    /// Session length in minutes (0 means "not recorded").
    var durationMinutes: Int
    var notes: String
    var createdAt: Date

    @Relationship var location: Location?

    /// Attempts in this session. Cascade-delete: removing a session removes its attempts.
    @Relationship(deleteRule: .cascade, inverse: \Attempt.session)
    var attempts: [Attempt]

    init(id: UUID = UUID(),
         date: Date = .now,
         durationMinutes: Int = 0,
         notes: String = "",
         createdAt: Date = .now,
         location: Location? = nil) {
        self.id = id
        self.date = date
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.createdAt = createdAt
        self.location = location
        self.attempts = []
    }

    /// Attempts ordered by their recorded position, then creation time.
    var orderedAttempts: [Attempt] {
        attempts.sorted {
            if $0.order != $1.order { return $0.order < $1.order }
            return $0.createdAt < $1.createdAt
        }
    }

    var sendCount: Int { attempts.filter { $0.outcome.isSend }.count }
    var attemptCount: Int { attempts.count }

    /// Hardest send in this session, as a canonical index per family. Returns nil
    /// when there are no sends.
    func hardestSendIndex(family: GradeFamily) -> Int? {
        attempts
            .filter { $0.outcome.isSend && $0.gradeFamily == family }
            .map(\.gradeIndex)
            .max()
    }

    /// A human duration label like "1h 45m" or "—".
    var durationLabel: String {
        guard durationMinutes > 0 else { return "—" }
        let h = durationMinutes / 60
        let m = durationMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}
