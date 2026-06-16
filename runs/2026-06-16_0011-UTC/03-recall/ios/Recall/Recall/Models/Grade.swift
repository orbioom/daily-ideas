import SwiftUI

/// The four answer grades a reviewer can give a card (Anki-style).
enum Grade: String, CaseIterable, Identifiable {
    case again
    case hard
    case good
    case easy

    var id: String { rawValue }

    var display: String {
        switch self {
        case .again: return "Again"
        case .hard: return "Hard"
        case .good: return "Good"
        case .easy: return "Easy"
        }
    }

    var color: Color {
        switch self {
        case .again: return Theme.bad
        case .hard: return Theme.warn
        case .good: return Theme.good
        case .easy: return Theme.accent
        }
    }

    var systemImage: String {
        switch self {
        case .again: return "arrow.counterclockwise"
        case .hard: return "tortoise.fill"
        case .good: return "checkmark"
        case .easy: return "hare.fill"
        }
    }

    /// "Again" and "Hard" count as misses for retention math.
    var isCorrect: Bool {
        switch self {
        case .again: return false
        case .hard, .good, .easy: return true
        }
    }
}
