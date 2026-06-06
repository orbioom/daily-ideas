import SwiftUI

/// Where a piece sits in its life cycle. Drives library grouping and the
/// suggested-next logic (retired pieces are excluded from suggestions).
enum PieceStatus: String, CaseIterable, Identifiable, Codable {
    case learning
    case polishing
    case maintenance
    case retired

    var id: String { rawValue }

    var title: String {
        switch self {
        case .learning:    return "Learning"
        case .polishing:   return "Polishing"
        case .maintenance: return "Maintenance"
        case .retired:     return "Retired"
        }
    }

    var systemImage: String {
        switch self {
        case .learning:    return "leaf"
        case .polishing:   return "sparkles"
        case .maintenance: return "arrow.triangle.2.circlepath"
        case .retired:     return "archivebox"
        }
    }

    /// Active pieces are eligible for practice suggestions.
    var isActive: Bool { self != .retired }

    /// Restrained tint — green only for the "in motion" states, calm grey for retired.
    var tint: Color {
        switch self {
        case .learning:    return Brand.live
        case .polishing:   return Brand.magic
        case .maintenance: return Brand.text2
        case .retired:     return Brand.text3
        }
    }
}

/// Coarse difficulty grade, kept simple and human.
enum Difficulty: Int, CaseIterable, Identifiable, Codable {
    case beginner = 1
    case easy = 2
    case intermediate = 3
    case advanced = 4
    case virtuoso = 5

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .beginner:     return "Beginner"
        case .easy:         return "Easy"
        case .intermediate: return "Intermediate"
        case .advanced:     return "Advanced"
        case .virtuoso:     return "Virtuoso"
        }
    }
}

/// How the session felt — a calm 1–5 quality scale written to the log.
enum SessionQuality: Int, CaseIterable, Identifiable, Codable {
    case rough = 1
    case shaky = 2
    case steady = 3
    case good = 4
    case flowing = 5

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .rough:   return "Rough"
        case .shaky:   return "Shaky"
        case .steady:  return "Steady"
        case .good:    return "Good"
        case .flowing: return "Flowing"
        }
    }

    var systemImage: String {
        switch self {
        case .rough:   return "cloud.rain"
        case .shaky:   return "wind"
        case .steady:  return "equal.circle"
        case .good:    return "checkmark.circle"
        case .flowing: return "wave.3.right"
        }
    }
}

/// Clamp a tempo into the supported metronome / target range.
enum Tempo {
    static let min = 20
    static let max = 300

    static func clamp(_ value: Int) -> Int {
        Swift.min(Swift.max(value, min), max)
    }
}
