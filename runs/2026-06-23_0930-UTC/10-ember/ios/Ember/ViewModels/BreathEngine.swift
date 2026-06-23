import Foundation
import SwiftUI

/// Segment kinds the engine emits, covering standard cycles and rounds sessions.
enum SegmentKind: Equatable {
    case prepare                 // count-in before the session begins
    case phase(BreathPhase)      // standard breathing phase
    case powerBreath(BreathPhase, index: Int, total: Int)
    case retention(Int)          // breath-hold (empty) for round N
    case recovery(Int)           // recovery hold (full) for round N
    case done
}

/// A single timed segment in the fully-expanded session timeline.
struct BreathSegment: Identifiable {
    let id = UUID()
    let kind: SegmentKind
    let duration: Double
    /// Orb fill at the START of this segment.
    let startFill: Double
    /// Orb fill at the END of this segment.
    let endFill: Double

    var title: String {
        switch kind {
        case .prepare: return "Get Ready"
        case .phase(let p): return p.title
        case .powerBreath(let p, _, _): return p.title
        case .retention: return "Hold Empty"
        case .recovery: return "Recovery Hold"
        case .done: return "Complete"
        }
    }

    var subtitle: String {
        switch kind {
        case .prepare: return "Settle in"
        case .phase(let p): return p.cue
        case .powerBreath(_, let i, let t): return "Breath \(i) of \(t)"
        case .retention(let r): return "Round \(r)"
        case .recovery(let r): return "Round \(r)"
        case .done: return ""
        }
    }

    /// Whether this segment counts as a completed cycle/round when it ends.
    var completesUnit: Bool {
        switch kind {
        case .phase(let p): return p == .holdOut || p == .exhale
        case .recovery: return true
        default: return false
        }
    }
}

/// Drives a guided breathing session. Time is derived from `Date` anchors so the
/// session stays correct across backgrounding; a display timer just nudges the UI.
@MainActor
@Observable
final class BreathEngine {
    enum State: Equatable { case idle, running, paused, finished }

    private(set) var state: State = .idle
    private(set) var pattern: BreathPattern
    private(set) var segments: [BreathSegment] = []

    /// Index of the segment currently playing.
    private(set) var currentIndex: Int = 0
    /// 0...1 progress through the current segment.
    private(set) var segmentProgress: Double = 0
    /// Smoothed orb fill 0 (contracted) ... 1 (expanded).
    private(set) var fill: Double = 0
    /// Whole-session elapsed breathing time in seconds.
    private(set) var elapsed: Double = 0
    /// Completed cycles/rounds so far.
    private(set) var unitsCompleted: Int = 0

    var totalDuration: Double { segments.reduce(0) { $0 + $1.duration } }

    /// Planned target length (seconds) used to know when to stop a looping pattern.
    private let targetSeconds: Double
    private let countdownEnabled: Bool

    // Wall-clock anchors.
    private var segmentStart: Date = .now
    private var accumulated: Double = 0   // elapsed before current run (across pauses)
    private var lastUnitIndex: Int = -1

    /// Called when the session naturally completes.
    var onComplete: (() -> Void)?

    init(pattern: BreathPattern, targetSeconds: Double, countdownEnabled: Bool) {
        self.pattern = pattern
        self.targetSeconds = max(20, targetSeconds)
        self.countdownEnabled = countdownEnabled
        self.segments = Self.buildSegments(pattern: pattern,
                                           targetSeconds: self.targetSeconds,
                                           countdownEnabled: countdownEnabled)
    }

    var currentSegment: BreathSegment? {
        guard segments.indices.contains(currentIndex) else { return nil }
        return segments[currentIndex]
    }

    /// Seconds remaining in the current segment (rounded up for the big counter).
    var segmentRemaining: Int {
        guard let seg = currentSegment else { return 0 }
        let remaining = seg.duration * (1 - segmentProgress)
        return max(0, Int(remaining.rounded(.up)))
    }

    var fractionComplete: Double {
        guard totalDuration > 0 else { return 0 }
        return min(1, elapsed / totalDuration)
    }

    // MARK: Controls

    func start() {
        guard state == .idle || state == .finished else { return }
        if state == .finished { reset() }
        state = .running
        segmentStart = .now
        Haptics.shared.phaseChange()
    }

    func pause() {
        guard state == .running else { return }
        accumulated += Date.now.timeIntervalSince(segmentStart)
        state = .paused
    }

    func resume() {
        guard state == .paused else { return }
        segmentStart = .now
        state = .running
    }

    func togglePause() {
        switch state {
        case .running: pause()
        case .paused: resume()
        default: break
        }
    }

    func skipSegment() {
        guard state == .running || state == .paused else { return }
        advanceToSegment(currentIndex + 1)
    }

    func reset() {
        state = .idle
        currentIndex = 0
        segmentProgress = 0
        fill = segments.first?.startFill ?? 0
        elapsed = 0
        unitsCompleted = 0
        accumulated = 0
        lastUnitIndex = -1
        segmentStart = .now
    }

    /// Called frequently by a TimelineView/timer to recompute derived state.
    func tick(now: Date = .now) {
        guard state == .running else { return }
        guard segments.indices.contains(currentIndex) else { finish(); return }

        let seg = segments[currentIndex]
        let segElapsed = accumulated + now.timeIntervalSince(segmentStart)

        if seg.duration <= 0 || segElapsed >= seg.duration {
            // Segment finished — credit any completed unit and advance.
            if seg.completesUnit && currentIndex != lastUnitIndex {
                unitsCompleted += 1
                lastUnitIndex = currentIndex
            }
            advanceToSegment(currentIndex + 1)
            return
        }

        segmentProgress = min(1, segElapsed / max(0.0001, seg.duration))
        fill = seg.startFill + (seg.endFill - seg.startFill) * easeInOut(segmentProgress)
        elapsed = elapsedBefore(currentIndex) + segElapsed
    }

    // MARK: Internal

    private func advanceToSegment(_ index: Int) {
        if index >= segments.count {
            finish()
            return
        }
        currentIndex = index
        segmentProgress = 0
        accumulated = 0
        segmentStart = .now
        fill = segments[index].startFill
        let kind = segments[index].kind
        if case .done = kind {
            finish()
            return
        }
        Haptics.shared.phaseChange()
    }

    private func finish() {
        guard state != .finished else { return }
        state = .finished
        segmentProgress = 1
        elapsed = totalDuration
        Haptics.shared.success()
        onComplete?()
    }

    private func elapsedBefore(_ index: Int) -> Double {
        guard index > 0 else { return 0 }
        return segments[0..<index].reduce(0) { $0 + $1.duration }
    }

    private func easeInOut(_ t: Double) -> Double {
        let c = min(1, max(0, t))
        return c * c * (3 - 2 * c)
    }

    // MARK: Timeline construction

    static func buildSegments(pattern: BreathPattern, targetSeconds: Double, countdownEnabled: Bool) -> [BreathSegment] {
        var segs: [BreathSegment] = []
        if countdownEnabled {
            segs.append(BreathSegment(kind: .prepare, duration: 3, startFill: 0.12, endFill: 0.12))
        }

        if pattern.isRounds {
            buildRounds(into: &segs, pattern: pattern)
        } else {
            buildStandard(into: &segs, pattern: pattern, targetSeconds: targetSeconds)
        }

        segs.append(BreathSegment(kind: .done, duration: 0, startFill: 0.2, endFill: 0.2))
        return segs
    }

    private static func buildStandard(into segs: inout [BreathSegment], pattern: BreathPattern, targetSeconds: Double) {
        let phases = pattern.activePhases
        let cycle = pattern.cycleSeconds
        let cycles = max(1, Int((targetSeconds / cycle).rounded()))
        var fill = 0.05
        for _ in 0..<cycles {
            for (phase, dur) in phases {
                let target = phase.targetFill
                segs.append(BreathSegment(kind: .phase(phase), duration: dur, startFill: fill, endFill: target))
                fill = target
            }
        }
    }

    private static func buildRounds(into segs: inout [BreathSegment], pattern: BreathPattern) {
        let breathIn = 1.6
        let breathOut = 1.4
        for round in 1...max(1, pattern.roundCount) {
            var fill = 0.1
            for i in 1...max(1, pattern.powerBreaths) {
                segs.append(BreathSegment(kind: .powerBreath(.inhale, index: i, total: pattern.powerBreaths),
                                          duration: breathIn, startFill: fill, endFill: 0.95))
                segs.append(BreathSegment(kind: .powerBreath(.exhale, index: i, total: pattern.powerBreaths),
                                          duration: breathOut, startFill: 0.95, endFill: 0.2))
                fill = 0.2
            }
            // Retention: full exhale then hold empty.
            segs.append(BreathSegment(kind: .retention(round),
                                      duration: pattern.retentionSeconds, startFill: 0.12, endFill: 0.12))
            // Recovery: big inhale then hold full.
            segs.append(BreathSegment(kind: .recovery(round),
                                      duration: pattern.recoverySeconds, startFill: 0.95, endFill: 0.95))
        }
    }
}
