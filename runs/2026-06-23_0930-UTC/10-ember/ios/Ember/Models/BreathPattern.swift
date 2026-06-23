import SwiftUI

/// The four canonical phases of a breathing cycle. Holds may be zero-length.
enum BreathPhase: String, Codable, CaseIterable, Identifiable {
    case inhale
    case holdIn      // hold after inhale (lungs full)
    case exhale
    case holdOut     // hold after exhale (lungs empty)

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inhale: return "Breathe In"
        case .holdIn: return "Hold"
        case .exhale: return "Breathe Out"
        case .holdOut: return "Hold"
        }
    }

    /// Short cue used in Reduce-Motion / VoiceOver text.
    var cue: String {
        switch self {
        case .inhale: return "In"
        case .holdIn: return "Hold full"
        case .exhale: return "Out"
        case .holdOut: return "Hold empty"
        }
    }

    /// Target normalized fill of the pacer orb during this phase (0 = small, 1 = expanded).
    var targetFill: Double {
        switch self {
        case .inhale: return 1.0
        case .holdIn: return 1.0
        case .exhale: return 0.0
        case .holdOut: return 0.0
        }
    }
}

/// The technique "family" — drives visuals, accent color, and engine behavior.
enum BreathStyle: String, Codable, CaseIterable, Identifiable {
    case box
    case relax
    case coherent
    case energize
    case rounds      // Wim-Hof-style: power breaths then a retention hold

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .box: return "Box Breathing"
        case .relax: return "4-7-8 Relax"
        case .coherent: return "Coherent 5-5"
        case .energize: return "Energize"
        case .rounds: return "Power Rounds"
        }
    }

    var accent: Color {
        switch self {
        case .box: return Theme.calmTeal
        case .relax: return Theme.deepBlue
        case .coherent: return Theme.calmTeal
        case .energize: return Theme.energyCoral
        case .rounds: return Theme.emberWarm
        }
    }

    var systemImage: String {
        switch self {
        case .box: return "square"
        case .relax: return "moon.stars"
        case .coherent: return "waveform.path.ecg"
        case .energize: return "bolt.fill"
        case .rounds: return "flame.fill"
        }
    }
}

/// A breathing technique definition. Standard styles use a fixed 4-phase loop;
/// `.rounds` adds a hyperventilation + retention structure handled by the engine.
struct BreathPattern: Identifiable, Hashable, Codable {
    let id: String
    var style: BreathStyle
    var name: String
    var subtitle: String
    var detail: String

    // Phase durations in seconds. Zero-length holds are simply skipped by the engine.
    var inhale: Double
    var holdIn: Double
    var exhale: Double
    var holdOut: Double

    // Rounds-only configuration (ignored for non-`.rounds` styles).
    var powerBreaths: Int        // quick breaths per round
    var retentionSeconds: Double // breath-hold (empty) after the power breaths
    var recoverySeconds: Double  // recovery hold (full) before the next round
    var roundCount: Int

    /// Seconds for one full standard cycle (sum of the four phases).
    var cycleSeconds: Double { max(0.5, inhale + holdIn + exhale + holdOut) }

    /// Ordered, non-zero phases for a single standard cycle.
    var activePhases: [(phase: BreathPhase, seconds: Double)] {
        var result: [(BreathPhase, Double)] = []
        if inhale > 0 { result.append((.inhale, inhale)) }
        if holdIn > 0 { result.append((.holdIn, holdIn)) }
        if exhale > 0 { result.append((.exhale, exhale)) }
        if holdOut > 0 { result.append((.holdOut, holdOut)) }
        // Guarantee at least one phase so the engine never divides by an empty set.
        if result.isEmpty { result.append((.inhale, 4)) }
        return result
    }

    var isRounds: Bool { style == .rounds }

    /// Human-readable rhythm string, e.g. "4-4-4-4" or "3 rounds".
    var rhythmLabel: String {
        if isRounds {
            return "\(roundCount) rounds · \(powerBreaths) breaths"
        }
        let parts = [inhale, holdIn, exhale, holdOut].map { sec -> String in
            let i = Int(sec.rounded())
            return "\(i)"
        }
        return parts.joined(separator: "-")
    }
}
