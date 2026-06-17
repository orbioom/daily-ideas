import SwiftUI

/// The kind of effort an interval represents.
enum IntervalKind: String, CaseIterable, Codable, Identifiable {
    case warmup
    case run
    case walk
    case cooldown

    var id: String { rawValue }

    /// Title-case label, e.g. "Run".
    var title: String {
        switch self {
        case .warmup:   return "Warm up"
        case .run:      return "Run"
        case .walk:     return "Walk"
        case .cooldown: return "Cool down"
        }
    }

    /// Short verb used on the big player label.
    var bigLabel: String {
        switch self {
        case .warmup:   return "WARM UP"
        case .run:      return "RUN"
        case .walk:     return "WALK"
        case .cooldown: return "COOL DOWN"
        }
    }

    /// The phrase spoken when this interval begins.
    var spokenCue: String {
        switch self {
        case .warmup:   return "Warm up. Brisk walk to get started."
        case .run:      return "Run now."
        case .walk:     return "Walk now."
        case .cooldown: return "Cool down. Ease off to a gentle walk."
        }
    }

    var color: Color {
        switch self {
        case .warmup:   return Theme.warmup
        case .run:      return Theme.run
        case .walk:     return Theme.walk
        case .cooldown: return Theme.cooldown
        }
    }

    var symbol: String {
        switch self {
        case .warmup:   return "figure.walk.motion"
        case .run:      return "figure.run"
        case .walk:     return "figure.walk"
        case .cooldown: return "wind"
        }
    }

    /// Whether this interval counts as active running time (for run-minute stats).
    var isRunning: Bool { self == .run }
}

/// A single ordered block within a session. A plain value type — the building
/// block of the timeline and a snapshot persisted with completed sessions.
struct Interval: Identifiable, Hashable, Codable {
    var id = UUID()
    var kind: IntervalKind
    var durationSeconds: Int

    init(id: UUID = UUID(), kind: IntervalKind, durationSeconds: Int) {
        self.id = id
        self.kind = kind
        // Guard: never allow a non-positive duration into the timeline.
        self.durationSeconds = max(1, durationSeconds)
    }

    /// Convenience constructors keep the plan tables readable.
    static func warmup(_ seconds: Int) -> Interval { Interval(kind: .warmup, durationSeconds: seconds) }
    static func run(_ seconds: Int) -> Interval { Interval(kind: .run, durationSeconds: seconds) }
    static func walk(_ seconds: Int) -> Interval { Interval(kind: .walk, durationSeconds: seconds) }
    static func cooldown(_ seconds: Int) -> Interval { Interval(kind: .cooldown, durationSeconds: seconds) }
}
