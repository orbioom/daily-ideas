import SwiftUI

/// How a study session presents cards.
enum ReviewMode: String, CaseIterable, Identifiable {
    case flip
    case multipleChoice
    case typeAnswer
    case cram

    var id: String { rawValue }

    var display: String {
        switch self {
        case .flip: return "Flip"
        case .multipleChoice: return "Multiple Choice"
        case .typeAnswer: return "Type Answer"
        case .cram: return "Cram"
        }
    }

    var shortName: String {
        switch self {
        case .flip: return "Flip"
        case .multipleChoice: return "Choice"
        case .typeAnswer: return "Type"
        case .cram: return "Cram"
        }
    }

    var systemImage: String {
        switch self {
        case .flip: return "rectangle.on.rectangle.angled"
        case .multipleChoice: return "list.bullet"
        case .typeAnswer: return "keyboard"
        case .cram: return "bolt.fill"
        }
    }

    var caption: String {
        switch self {
        case .flip: return "Reveal the answer, then grade yourself."
        case .multipleChoice: return "Pick the right answer from four options."
        case .typeAnswer: return "Type the answer; we check it for you."
        case .cram: return "Drill the whole deck — scheduling untouched."
        }
    }

    /// Cram never writes SRS state back; it's a pure review drill.
    var affectsSchedule: Bool { self != .cram }
}
