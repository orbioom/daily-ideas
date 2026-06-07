import Foundation

/// One round of a table: a breath-hold followed by a rest (recovery breathing).
struct ApneaRound: Identifiable {
    let id = UUID()
    let index: Int        // 1-based
    let holdSeconds: Int
    let restSeconds: Int
}

/// A single phase in the live session timeline.
enum PhaseKind { case breatheUp, hold, rest, done }

struct Phase: Identifiable {
    let id = UUID()
    let kind: PhaseKind
    let round: Int        // 0 for the opening breathe-up
    let duration: Int     // seconds
    let start: Int        // cumulative start offset (seconds)
    var end: Int { start + duration }
}

/// Pure generation of CO₂/O₂ table schedules and the session phase timeline.
///
/// The conventions follow standard freediving practice:
///  • CO₂ table — the hold is held constant (≈ half your max) while the rest
///    shrinks each round, so carbon dioxide accumulates.
///  • O₂ table — the rest is held constant while the hold grows toward your max,
///    pushing oxygen lower each round.
enum TableEngine {

    static let breatheUpSeconds = 120

    static func schedule(type: TableType, maxHold: Int, rounds: Int) -> [ApneaRound] {
        let n = max(2, min(12, rounds))
        let mx = max(30, maxHold)
        switch type {
        case .co2:
            let hold = Int((Double(mx) * 0.5).rounded())
            let restStart = 105
            let restStep = 15
            return (0..<n).map { i in
                let rest = max(15, restStart - i * restStep)
                return ApneaRound(index: i + 1, holdSeconds: hold, restSeconds: rest)
            }
        case .o2:
            let rest = 120
            let holdStart = Int((Double(mx) * 0.40).rounded())
            let holdEnd = Int((Double(mx) * 0.80).rounded())
            return (0..<n).map { i in
                let t = n > 1 ? Double(i) / Double(n - 1) : 1
                let hold = Int((Double(holdStart) + (Double(holdEnd - holdStart)) * t).rounded())
                // Last round has no trailing rest.
                let r = (i == n - 1) ? 0 : rest
                return ApneaRound(index: i + 1, holdSeconds: hold, restSeconds: r)
            }
        }
    }

    static func totalSeconds(_ rounds: [ApneaRound]) -> Int {
        breatheUpSeconds + rounds.map { $0.holdSeconds + $0.restSeconds }.reduce(0, +)
    }

    /// Flatten a schedule into an ordered phase timeline with cumulative offsets.
    static func phases(_ rounds: [ApneaRound]) -> [Phase] {
        var out: [Phase] = []
        var cursor = 0
        out.append(Phase(kind: .breatheUp, round: 0, duration: breatheUpSeconds, start: cursor))
        cursor += breatheUpSeconds
        for r in rounds {
            out.append(Phase(kind: .hold, round: r.index, duration: r.holdSeconds, start: cursor))
            cursor += r.holdSeconds
            if r.restSeconds > 0 {
                out.append(Phase(kind: .rest, round: r.index, duration: r.restSeconds, start: cursor))
                cursor += r.restSeconds
            }
        }
        out.append(Phase(kind: .done, round: 0, duration: 0, start: cursor))
        return out
    }

    /// Format seconds as m:ss.
    static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
