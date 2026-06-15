import SwiftUI

/// The kinds of phase in a training session.
enum Phase: String, CaseIterable, Hashable {
    case squeeze
    case hold
    case relax
    case rest

    var label: String {
        switch self {
        case .squeeze: return "Squeeze"
        case .hold: return "Hold"
        case .relax: return "Relax"
        case .rest: return "Rest"
        }
    }

    /// Short coaching line shown beneath the ring.
    var guidance: String {
        switch self {
        case .squeeze: return "Draw up and in — gently lift your pelvic-floor muscles."
        case .hold: return "Keep the lift steady. Breathe normally."
        case .relax: return "Fully let go. Soften completely before the next rep."
        case .rest: return "Rest and breathe. The next set is coming up."
        }
    }

    var color: Color {
        switch self {
        case .squeeze: return Theme.squeeze
        case .hold: return Theme.hold
        case .relax: return Theme.relax
        case .rest: return Theme.rest
        }
    }

    var symbol: String {
        switch self {
        case .squeeze: return "arrow.up.circle.fill"
        case .hold: return "pause.circle.fill"
        case .relax: return "arrow.down.circle.fill"
        case .rest: return "moon.zzz.fill"
        }
    }

    /// Normalized ring scale target for this phase (1 = fully expanded squeeze).
    var ringTarget: CGFloat {
        switch self {
        case .squeeze: return 1.0
        case .hold: return 1.0
        case .relax: return 0.45
        case .rest: return 0.4
        }
    }
}

/// A single contiguous segment of the session timeline.
struct PhaseStep: Identifiable, Hashable {
    let id: Int          // ordinal index in the timeline
    let phase: Phase
    let seconds: Int
    /// 1-based rep number this step belongs to (0 for set-break rests).
    let rep: Int
    /// 1-based set number this step belongs to.
    let set: Int
}

/// A snapshot of where the session is at a given elapsed time.
struct SessionMoment: Equatable {
    let stepIndex: Int
    let phase: Phase
    /// Seconds elapsed within the current step.
    let elapsedInStep: Double
    /// Seconds remaining in the current step (>= 0).
    let remainingInStep: Double
    let rep: Int
    let set: Int
    /// Fraction through the current step, 0...1.
    let stepProgress: Double
    /// Fraction through the whole session, 0...1.
    let overallProgress: Double
    /// True once elapsed has passed the end of the timeline.
    let isComplete: Bool
}

/// Pure, testable expansion of a TrainingProgram into a wall-clock timeline.
struct SessionEngine {
    let steps: [PhaseStep]
    let totalSeconds: Int
    let totalReps: Int
    let totalSets: Int

    init(program: TrainingProgram) {
        let reps = max(1, program.reps)
        let sets = max(1, program.sets)
        let contract = max(0, program.contractSeconds)
        let hold = max(0, program.holdSeconds)
        let relax = max(0, program.relaxSeconds)
        let rest = max(0, program.restSeconds)

        var built: [PhaseStep] = []
        var ordinal = 0
        for s in 1...sets {
            for r in 1...reps {
                if contract > 0 {
                    built.append(PhaseStep(id: ordinal, phase: .squeeze, seconds: contract, rep: r, set: s))
                    ordinal += 1
                }
                if hold > 0 {
                    built.append(PhaseStep(id: ordinal, phase: .hold, seconds: hold, rep: r, set: s))
                    ordinal += 1
                }
                if relax > 0 {
                    built.append(PhaseStep(id: ordinal, phase: .relax, seconds: relax, rep: r, set: s))
                    ordinal += 1
                }
            }
            // Rest between sets (not after the last set).
            if s < sets && rest > 0 {
                built.append(PhaseStep(id: ordinal, phase: .rest, seconds: rest, rep: 0, set: s))
                ordinal += 1
            }
        }

        // Guarantee at least one step so downstream math never divides by an empty timeline.
        if built.isEmpty {
            built.append(PhaseStep(id: 0, phase: .squeeze, seconds: max(1, contract), rep: 1, set: 1))
        }

        self.steps = built
        self.totalSeconds = built.reduce(0) { $0 + $1.seconds }
        self.totalReps = reps * sets
        self.totalSets = sets
    }

    /// Cumulative start time (in seconds) for each step.
    private var stepStarts: [Double] {
        var acc: Double = 0
        var starts: [Double] = []
        for step in steps {
            starts.append(acc)
            acc += Double(step.seconds)
        }
        return starts
    }

    /// Resolve the moment at a wall-clock elapsed time. Robust to elapsed beyond total.
    func moment(at elapsed: Double) -> SessionMoment {
        let total = max(1, totalSeconds)
        let clampedElapsed = max(0, elapsed)
        let overall = min(1.0, clampedElapsed / Double(total))

        if clampedElapsed >= Double(totalSeconds) {
            let last = steps.last ?? PhaseStep(id: 0, phase: .relax, seconds: 1, rep: totalReps, set: totalSets)
            return SessionMoment(
                stepIndex: steps.count - 1,
                phase: last.phase,
                elapsedInStep: Double(last.seconds),
                remainingInStep: 0,
                rep: last.rep == 0 ? totalReps : last.rep,
                set: last.set,
                stepProgress: 1,
                overallProgress: 1,
                isComplete: true
            )
        }

        let starts = stepStarts
        var index = 0
        for (i, start) in starts.enumerated() {
            let dur = Double(steps[i].seconds)
            if clampedElapsed >= start && clampedElapsed < start + dur {
                index = i
                break
            }
            index = i
        }

        let step = steps[index]
        let start = starts[index]
        let dur = max(1, Double(step.seconds))
        let inStep = min(dur, clampedElapsed - start)
        let remaining = max(0, dur - inStep)
        let progress = min(1.0, max(0, inStep / dur))

        return SessionMoment(
            stepIndex: index,
            phase: step.phase,
            elapsedInStep: inStep,
            remainingInStep: remaining,
            rep: step.rep == 0 ? max(1, step.set) : step.rep,
            set: step.set,
            stepProgress: progress,
            overallProgress: overall,
            isComplete: false
        )
    }

    /// Count of completed reps at a given elapsed time. A rep is "complete" once the last
    /// work-phase step belonging to that (set, rep) pair has fully elapsed.
    func completedReps(at elapsed: Double) -> Int {
        if elapsed >= Double(totalSeconds) { return totalReps }
        let starts = stepStarts
        // Track the highest (set, rep) whose final work step has finished.
        var completed = 0
        var seen = Set<Int>()                 // encoded set*10000+rep keys already counted
        for (i, step) in steps.enumerated() where step.phase != .rest {
            let key = step.set * 10000 + step.rep
            let end = starts[i] + Double(step.seconds)
            // Only count a rep once all of its work steps have passed.
            if elapsed >= end && isLastWorkStep(of: step, atIndex: i) && !seen.contains(key) {
                seen.insert(key)
                completed += 1
            }
        }
        return min(totalReps, completed)
    }

    /// True if the step at `index` is the final work (non-rest) step of its (set, rep) pair.
    private func isLastWorkStep(of step: PhaseStep, atIndex index: Int) -> Bool {
        let next = index + 1
        guard next < steps.count else { return true }
        let n = steps[next]
        // If the next step is a rest, or belongs to a different rep/set, this is the last work step.
        if n.phase == .rest { return true }
        return !(n.set == step.set && n.rep == step.rep)
    }

    /// Human-friendly est. duration string.
    var durationLabel: String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        if m == 0 { return "\(s)s" }
        if s == 0 { return "\(m) min" }
        return "\(m) min \(s)s"
    }
}
