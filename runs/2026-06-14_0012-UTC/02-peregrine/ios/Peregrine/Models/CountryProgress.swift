import Foundation
import SwiftData

/// Per-country learning record. One row per ISO-2 code the learner has
/// encountered (or starred). Mastery is derived, never stored, so it always
/// reflects the latest seen/correct counts.
@Model
final class CountryProgress {
    @Attribute(.unique) var iso2: String
    var seen: Int
    var correct: Int
    var lastSeen: Date?
    var starred: Bool

    init(iso2: String,
         seen: Int = 0,
         correct: Int = 0,
         lastSeen: Date? = nil,
         starred: Bool = false) {
        self.iso2 = iso2
        self.seen = seen
        self.correct = correct
        self.lastSeen = lastSeen
        self.starred = starred
    }

    /// Accuracy in 0...1, guarded against division by zero.
    var accuracy: Double {
        guard seen > 0 else { return 0 }
        return Double(correct) / Double(seen)
    }

    /// Mastery in 0...1 combining accuracy with exposure so that a single lucky
    /// answer does not read as "mastered". Confidence ramps with repetitions.
    var mastery: Double {
        guard seen > 0 else { return 0 }
        let confidence = min(1.0, Double(seen) / 4.0)
        return accuracy * confidence
    }

    var level: MasteryLevel {
        if seen == 0 { return .unseen }
        switch mastery {
        case ..<0.34: return .learning
        case ..<0.7: return .familiar
        default: return .mastered
        }
    }
}

/// Coarse mastery buckets used for rings, badges and copy.
enum MasteryLevel: String, CaseIterable, Hashable {
    case unseen
    case learning
    case familiar
    case mastered

    var label: String {
        switch self {
        case .unseen: return "New"
        case .learning: return "Learning"
        case .familiar: return "Familiar"
        case .mastered: return "Mastered"
        }
    }
}
