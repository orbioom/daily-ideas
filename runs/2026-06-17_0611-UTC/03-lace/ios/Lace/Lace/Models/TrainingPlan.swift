import SwiftUI

/// A single training session: an ordered list of intervals.
struct PlanSession: Identifiable, Hashable {
    let id: String          // stable, e.g. "c25k-w1-s1"
    let intervals: [Interval]

    var totalSeconds: Int { intervals.reduce(0) { $0 + $1.durationSeconds } }
    var runSeconds: Int { intervals.filter { $0.kind.isRunning }.reduce(0) { $0 + $1.durationSeconds } }

    /// Count of run reps (distinct run intervals) — the headline of a session.
    var runReps: Int { intervals.filter { $0.kind == .run }.count }

    /// A compact human description, e.g. "Run 60s · Walk 90s × 8".
    var summary: String {
        let runs = intervals.filter { $0.kind == .run }.map(\.durationSeconds)
        let walks = intervals.filter { $0.kind == .walk }.map(\.durationSeconds)
        guard let firstRun = runs.first else {
            // Pure walk session (rare) — describe by total.
            return "Brisk walk \(Fmt.minutes(totalSeconds))"
        }
        let uniformRun = runs.allSatisfy { $0 == firstRun }
        if uniformRun, let firstWalk = walks.first, walks.allSatisfy({ $0 == firstWalk }) {
            return "Run \(Fmt.clock(firstRun)) · Walk \(Fmt.clock(firstWalk)) × \(runs.count)"
        }
        if uniformRun, walks.isEmpty {
            return "Run \(Fmt.minutes(firstRun)) continuous"
        }
        // Mixed/ladder session.
        return "\(runs.count) run intervals · \(Fmt.minutes(totalSeconds)) total"
    }
}

/// A week of three sessions.
struct PlanWeek: Identifiable, Hashable {
    let id: Int             // 1-based week number
    let focus: String       // a short motivational descriptor
    let sessions: [PlanSession]

    var weekNumber: Int { id }
}

/// A complete training plan (built-in or expanded from a custom plan).
struct TrainingPlan: Identifiable, Hashable {
    let id: String          // e.g. "c25k", "easy-start", "bridge-10k", or "custom-<uuid>"
    let title: String
    let subtitle: String
    let symbol: String
    let isPro: Bool         // whether enrolling requires Pro
    let weeks: [PlanWeek]

    var totalSessions: Int { weeks.reduce(0) { $0 + $1.sessions.count } }
    var weekCount: Int { weeks.count }

    /// Safe lookup of a specific session by week number (1-based) and index.
    func session(week: Int, index: Int) -> PlanSession? {
        guard let w = weeks.first(where: { $0.weekNumber == week }) else { return nil }
        return w.sessions[safe: index]
    }

    /// The flat ordered list of (week, index, session) for progress math.
    var flatSessions: [(week: Int, index: Int, session: PlanSession)] {
        var out: [(Int, Int, PlanSession)] = []
        for w in weeks {
            for (i, s) in w.sessions.enumerated() {
                out.append((w.weekNumber, i, s))
            }
        }
        return out
    }
}
