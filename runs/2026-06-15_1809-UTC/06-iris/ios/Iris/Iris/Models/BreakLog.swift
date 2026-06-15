import Foundation
import SwiftData

/// The kind of restful pause that was logged.
enum BreakKind: String, Codable, CaseIterable {
    case twentyRule   // a 20-20-20 micro-break
    case longRest     // a longer screen rest
    case exercise     // a completed guided exercise routine (mirrored for the dashboard)

    var label: String {
        switch self {
        case .twentyRule: return "20-20-20 break"
        case .longRest: return "Long rest"
        case .exercise: return "Eye exercise"
        }
    }

    var symbol: String {
        switch self {
        case .twentyRule: return "eye"
        case .longRest: return "moon.zzz"
        case .exercise: return "figure.mind.and.body"
        }
    }
}

/// A logged restful pause from screens. The dashboard and stats build entirely on these.
@Model
final class BreakLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var kindRaw: String
    var durationSeconds: Int
    var completed: Bool

    init(id: UUID = UUID(),
         date: Date = .now,
         kind: BreakKind = .twentyRule,
         durationSeconds: Int = 20,
         completed: Bool = true) {
        self.id = id
        self.date = date
        self.kindRaw = kind.rawValue
        self.durationSeconds = durationSeconds
        self.completed = completed
    }

    var kind: BreakKind {
        BreakKind(rawValue: kindRaw) ?? .twentyRule
    }
}
