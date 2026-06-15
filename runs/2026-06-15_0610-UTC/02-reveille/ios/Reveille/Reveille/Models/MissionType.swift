import SwiftUI

/// A dismiss mission — the task you must complete to silence an alarm.
enum MissionType: String, Codable, CaseIterable, Identifiable {
    case none
    case math
    case memory
    case tap
    case shake
    case typing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:   return "None"
        case .math:   return "Math"
        case .memory: return "Memory"
        case .tap:    return "Tap Targets"
        case .shake:  return "Shake"
        case .typing: return "Steady Type"
        }
    }

    var shortTitle: String {
        switch self {
        case .none:   return "Tap to stop"
        case .math:   return "Solve math"
        case .memory: return "Repeat pattern"
        case .tap:    return "Tap the dots"
        case .shake:  return "Shake awake"
        case .typing: return "Type the phrase"
        }
    }

    var symbol: String {
        switch self {
        case .none:   return "hand.tap"
        case .math:   return "plus.forwardslash.minus"
        case .memory: return "square.grid.2x2"
        case .tap:    return "circle.dotted"
        case .shake:  return "iphone.gen3.radiowaves.left.and.right"
        case .typing: return "keyboard"
        }
    }

    var detail: String {
        switch self {
        case .none:   return "A single Stop button. Best for light sleepers."
        case .math:   return "Solve arithmetic problems. Wakes your brain fast."
        case .memory: return "Watch a tile sequence light up, then repeat it."
        case .tap:    return "Tap dots as they appear before they fade."
        case .shake:  return "Physically shake your phone until the meter fills."
        case .typing: return "Type a short phrase exactly to prove you're up."
        }
    }

    /// Whether this mission is free (Math + Shake) or requires Pro.
    var isFree: Bool {
        self == .none || self == .math || self == .shake
    }
}

/// Mission difficulty — scales problem count, sequence length, target speed, etc.
enum MissionDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy:   return "Easy"
        case .medium: return "Medium"
        case .hard:   return "Hard"
        }
    }

    /// Multiplier applied to base difficulty parameters.
    var factor: Int {
        switch self {
        case .easy:   return 1
        case .medium: return 2
        case .hard:   return 3
        }
    }
}
