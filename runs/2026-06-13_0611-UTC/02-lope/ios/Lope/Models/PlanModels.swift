import Foundation
import SwiftData

// MARK: - Program catalog (value types, defined in code)

enum SegmentKind: String, Codable, Hashable {
    case warmup, run, walk, cooldown
    var label: String {
        switch self {
        case .warmup: return "Warm up"
        case .run: return "Run"
        case .walk: return "Walk"
        case .cooldown: return "Cool down"
        }
    }
    var icon: String {
        switch self {
        case .warmup: return "figure.walk.motion"
        case .run: return "figure.run"
        case .walk: return "figure.walk"
        case .cooldown: return "wind"
        }
    }
}

struct Segment: Identifiable, Hashable {
    let id = UUID()
    let kind: SegmentKind
    let seconds: Int
}

struct Workout: Identifiable, Hashable {
    let id = UUID()
    let segments: [Segment]

    var totalSeconds: Int { segments.reduce(0) { $0 + $1.seconds } }
    var runSeconds: Int { segments.filter { $0.kind == .run }.reduce(0) { $0 + $1.seconds } }

    /// Human summary like "Run 5 min × 3, walk 3 min between".
    var summary: String {
        let runs = segments.filter { $0.kind == .run }.map(\.seconds)
        guard !runs.isEmpty else { return "Easy walk, \(totalSeconds / 60) min" }
        let uniqueRuns = Set(runs)
        if uniqueRuns.count == 1, let r = uniqueRuns.first {
            let walks = segments.filter { $0.kind == .walk }.map(\.seconds)
            let walk = walks.first ?? 0
            if runs.count == 1 {
                return "Run \(fmt(r)) nonstop"
            }
            return "Run \(fmt(r)) × \(runs.count), walk \(fmt(walk)) between"
        }
        return "\(runs.count) runs up to \(fmt(runs.max() ?? 0))"
    }

    private func fmt(_ s: Int) -> String {
        if s % 60 == 0 { return "\(s / 60) min" }
        if s < 60 { return "\(s) sec" }
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

struct WeekPlan: Identifiable {
    let id = UUID()
    let number: Int
    let note: String
    let sessions: [Workout]   // always 3 sessions

    var minutesPerSession: Int { (sessions.first?.totalSeconds ?? 0) / 60 }
}

struct RunPlan: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let blurb: String
    let weeks: [WeekPlan]

    var totalSessions: Int { weeks.count * 3 }
}

// MARK: - User-owned record

@Model
final class RunLog {
    var date: Date
    var planID: String
    var planName: String
    var weekNumber: Int
    var sessionIndex: Int        // 0..2 within the week
    var title: String
    var plannedSeconds: Int
    var activeSeconds: Int       // actual time spent running the workout
    var distanceMeters: Double   // 0 if not entered
    var rating: Int              // 1...5, how it felt
    var note: String

    init(date: Date = .now, planID: String, planName: String, weekNumber: Int,
         sessionIndex: Int, title: String, plannedSeconds: Int,
         activeSeconds: Int, distanceMeters: Double = 0, rating: Int = 3, note: String = "") {
        self.date = date
        self.planID = planID
        self.planName = planName
        self.weekNumber = weekNumber
        self.sessionIndex = sessionIndex
        self.title = title
        self.plannedSeconds = plannedSeconds
        self.activeSeconds = activeSeconds
        self.distanceMeters = distanceMeters
        self.rating = rating
        self.note = note
    }

    /// Pace in seconds per km, or nil if no distance.
    var paceSecPerKm: Double? {
        guard distanceMeters > 50 else { return nil }
        return Double(activeSeconds) / (distanceMeters / 1000.0)
    }
}
