import Foundation
import SwiftUI

enum BreathPhase: String {
    case inhale = "Breathe in"
    case holdIn = "Hold"
    case exhale = "Breathe out"
    case holdOut = "Hold"

    /// Orb scale target for this phase (1 = small, fully exhaled).
    var targetScale: CGFloat {
        switch self {
        case .inhale: return 1.0   // growing toward big
        case .holdIn: return 1.0
        case .exhale: return 0.45
        case .holdOut: return 0.45
        }
    }
}

/// The live state of a guided breathing session at a given elapsed time.
struct BreathState {
    let phase: BreathPhase
    let phaseDuration: Double
    let timeIntoPhase: Double
    let round: Int            // 1-based
    let totalRounds: Int
    let overallProgress: Double
    let finished: Bool

    var phaseRemaining: Double { max(0, phaseDuration - timeIntoPhase) }
    var phaseProgress: Double { phaseDuration <= 0 ? 1 : min(1, timeIntoPhase / phaseDuration) }

    /// Continuous 0.45...1.0 orb scale, eased across the active phase.
    var orbScale: CGFloat {
        let small: CGFloat = 0.45, big: CGFloat = 1.0
        switch phase {
        case .inhale: return small + (big - small) * easeInOut(phaseProgress)
        case .holdIn: return big
        case .exhale: return big - (big - small) * easeInOut(phaseProgress)
        case .holdOut: return small
        }
    }

    private func easeInOut(_ t: Double) -> CGFloat {
        CGFloat(t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2)
    }
}

enum BreathEngine {
    /// Ordered non-zero phases for one round of a pattern.
    static func phases(for pattern: BreathPattern) -> [(BreathPhase, Double)] {
        var result: [(BreathPhase, Double)] = []
        if pattern.inhale > 0 { result.append((.inhale, pattern.inhale)) }
        if pattern.holdIn > 0 { result.append((.holdIn, pattern.holdIn)) }
        if pattern.exhale > 0 { result.append((.exhale, pattern.exhale)) }
        if pattern.holdOut > 0 { result.append((.holdOut, pattern.holdOut)) }
        if result.isEmpty { result.append((.inhale, 4)); result.append((.exhale, 4)) }
        return result
    }

    static func state(for pattern: BreathPattern, elapsed: Double) -> BreathState {
        let roundPhases = phases(for: pattern)
        let roundLen = roundPhases.reduce(0) { $0 + $1.1 }
        let total = roundLen * Double(pattern.rounds)
        if elapsed >= total {
            let last = roundPhases.last ?? (.exhale, 4)
            return BreathState(phase: last.0, phaseDuration: last.1, timeIntoPhase: last.1,
                               round: pattern.rounds, totalRounds: pattern.rounds,
                               overallProgress: 1, finished: true)
        }
        let roundIndex = Int(elapsed / roundLen)
        var t = elapsed - Double(roundIndex) * roundLen
        for (phase, dur) in roundPhases {
            if t < dur {
                return BreathState(phase: phase, phaseDuration: dur, timeIntoPhase: t,
                                   round: roundIndex + 1, totalRounds: pattern.rounds,
                                   overallProgress: min(1, elapsed / total), finished: false)
            }
            t -= dur
        }
        let last = roundPhases.last ?? (.exhale, 4)
        return BreathState(phase: last.0, phaseDuration: last.1, timeIntoPhase: last.1,
                           round: roundIndex + 1, totalRounds: pattern.rounds,
                           overallProgress: min(1, elapsed / total), finished: false)
    }

    static func clock(_ seconds: Double) -> String {
        let s = Int(max(0, seconds.rounded()))
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
