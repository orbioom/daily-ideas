import Foundation
import Observation

// MARK: - Breathing patterns

enum BreathPattern: String, CaseIterable, Identifiable {
    case calm        // inhale 4 / exhale 6
    case box         // 4-4-4-4
    case fourSevenEight
    case coherent    // 5-5

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm: return "Calm"
        case .box: return "Box"
        case .fourSevenEight: return "4-7-8"
        case .coherent: return "Coherent"
        }
    }

    var subtitle: String {
        switch self {
        case .calm: return "Inhale 4 · Exhale 6"
        case .box: return "4 · 4 · 4 · 4"
        case .fourSevenEight: return "Inhale 4 · Hold 7 · Exhale 8"
        case .coherent: return "Inhale 5 · Exhale 5"
        }
    }

    /// Whether this pattern is available on the free tier.
    var isFree: Bool {
        switch self {
        case .calm, .coherent: return true
        case .box, .fourSevenEight: return false
        }
    }

    /// Phase durations in seconds, in order: inhale, hold-in, exhale, hold-out.
    /// A zero-duration phase is skipped.
    var phases: [BreathPhaseSpec] {
        switch self {
        case .calm:
            return [.init(.inhale, 4), .init(.exhale, 6)]
        case .box:
            return [.init(.inhale, 4), .init(.holdIn, 4), .init(.exhale, 4), .init(.holdOut, 4)]
        case .fourSevenEight:
            return [.init(.inhale, 4), .init(.holdIn, 7), .init(.exhale, 8)]
        case .coherent:
            return [.init(.inhale, 5), .init(.exhale, 5)]
        }
    }

    /// Total seconds for one full cycle.
    var cycleDuration: Double { phases.reduce(0) { $0 + $1.duration } }
}

enum BreathPhaseKind: String {
    case inhale, holdIn, exhale, holdOut

    var word: String {
        switch self {
        case .inhale: return "Breathe in"
        case .holdIn: return "Hold"
        case .exhale: return "Breathe out"
        case .holdOut: return "Hold"
        }
    }

    /// Target orb scale at the END of this phase (start derived from previous).
    var targetScale: Double {
        switch self {
        case .inhale: return 1.0
        case .holdIn: return 1.0
        case .exhale: return 0.45
        case .holdOut: return 0.45
        }
    }
}

struct BreathPhaseSpec {
    let kind: BreathPhaseKind
    let duration: Double
    init(_ kind: BreathPhaseKind, _ duration: Double) {
        self.kind = kind
        self.duration = duration
    }
}

/// A resolved snapshot of where we are in the breathing timeline.
struct BreathTick {
    let kind: BreathPhaseKind
    /// Whole seconds remaining in the current phase (for the countdown).
    let secondsRemaining: Int
    /// 0…1 progress within the current phase.
    let phaseProgress: Double
    /// Eased orb scale (0.45…1.0). Static callers can ignore this.
    let scale: Double
    /// Whether we just crossed into a new phase since the last tick.
    let didChangePhase: Bool
}

// MARK: - Engine

/// Drives a breathing session from wall-clock elapsed time so it stays correct
/// across backgrounding and view re-creation (no accumulated timer drift).
@Observable
final class BreathEngine {

    private(set) var pattern: BreathPattern
    private(set) var isRunning = false

    /// Absolute time the (running) session started, minus paused offset.
    private var sessionStart: Date?
    /// Accumulated active seconds captured at the last pause.
    private var accumulatedBeforePause: Double = 0
    /// Last phase kind we reported (to detect changes for haptics).
    private var lastReportedKind: BreathPhaseKind?

    init(pattern: BreathPattern = .calm) {
        self.pattern = pattern
    }

    // MARK: Controls

    func setPattern(_ new: BreathPattern) {
        pattern = new
        reset()
    }

    func start() {
        guard !isRunning else { return }
        sessionStart = Date().addingTimeInterval(-accumulatedBeforePause)
        isRunning = true
    }

    func pause() {
        guard isRunning, let start = sessionStart else { return }
        accumulatedBeforePause = Date().timeIntervalSince(start)
        isRunning = false
        sessionStart = nil
    }

    func toggle() { isRunning ? pause() : start() }

    func reset() {
        isRunning = false
        sessionStart = nil
        accumulatedBeforePause = 0
        lastReportedKind = nil
    }

    /// Total active elapsed seconds in this session.
    var elapsedSeconds: Double {
        if let start = sessionStart, isRunning {
            return max(0, Date().timeIntervalSince(start))
        }
        return accumulatedBeforePause
    }

    /// Completed full minutes of breathing.
    var minutesDone: Int { Int(elapsedSeconds / 60) }

    /// Number of completed breath cycles.
    var cyclesDone: Int {
        let cycle = pattern.cycleDuration
        guard cycle > 0 else { return 0 }
        return Int(elapsedSeconds / cycle)
    }

    // MARK: Timeline resolution

    /// Compute the current phase snapshot from elapsed wall-clock time.
    /// Mutating only to track phase-change for haptic cueing.
    func tick(at date: Date = .now) -> BreathTick {
        let elapsed: Double
        if let start = sessionStart, isRunning {
            elapsed = max(0, date.timeIntervalSince(start))
        } else {
            elapsed = accumulatedBeforePause
        }

        let phases = pattern.phases
        let cycle = pattern.cycleDuration
        guard cycle > 0, !phases.isEmpty else {
            return BreathTick(kind: .inhale, secondsRemaining: 0, phaseProgress: 0, scale: 0.45, didChangePhase: false)
        }

        let inCycle = elapsed.truncatingRemainder(dividingBy: cycle)

        // Walk phases to find where we are. `previousTarget` is the orb scale at
        // the moment the current phase begins (i.e. the prior phase's target, or
        // the resting scale at the very start of a cycle).
        let restingScale = 0.45
        var acc = 0.0
        var current = phases[0]
        var phaseStartScale = restingScale
        var localTime = inCycle
        var previousTarget = restingScale

        for (index, spec) in phases.enumerated() {
            let isLast = (index == phases.count - 1)
            if inCycle < acc + spec.duration || isLast {
                current = spec
                localTime = inCycle - acc
                phaseStartScale = previousTarget
                break
            }
            acc += spec.duration
            previousTarget = spec.kind.targetScale
        }

        let dur = max(0.0001, current.duration)
        let progress = (localTime / dur).clamped(to: 0...1)
        let remaining = Int(ceil(max(0, current.duration - localTime)))

        // Eased interpolation between start and target scale.
        let target = current.kind.targetScale
        let eased = easeInOut(progress)
        let scale = phaseStartScale + (target - phaseStartScale) * eased

        let changed = (lastReportedKind != current.kind)
        if isRunning { lastReportedKind = current.kind }

        return BreathTick(
            kind: current.kind,
            secondsRemaining: max(remaining, 0),
            phaseProgress: progress,
            scale: scale,
            didChangePhase: changed
        )
    }

    private func easeInOut(_ t: Double) -> Double {
        let x = t.clamped(to: 0...1)
        return x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2
    }
}
