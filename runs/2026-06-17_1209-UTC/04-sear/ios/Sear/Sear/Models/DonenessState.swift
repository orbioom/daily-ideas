import SwiftUI

/// Live classification of current internal temp vs target, from TempEngine.
enum DonenessState: String, Identifiable {
    case under          // still climbing, well below target
    case almost         // within striking distance of target
    case done           // at or above target — pull it
    case resting        // pulled, carryover happening
    case overcooked     // pushed well past target
    var id: String { rawValue }

    var label: String {
        switch self {
        case .under: return "Climbing"
        case .almost: return "Almost there"
        case .done: return "Pull it"
        case .resting: return "Resting"
        case .overcooked: return "Past target"
        }
    }

    var detail: String {
        switch self {
        case .under: return "Keep the lid down and let it ride."
        case .almost: return "Closing in on target — stay nearby."
        case .done: return "At target. Pull and rest now."
        case .resting: return "Carryover is finishing the cook."
        case .overcooked: return "Above target. Pull immediately."
        }
    }

    var symbol: String {
        switch self {
        case .under: return "arrow.up.right"
        case .almost: return "timer"
        case .done: return "checkmark.circle.fill"
        case .resting: return "pause.circle.fill"
        case .overcooked: return "exclamationmark.triangle.fill"
        }
    }

    var hue: Color {
        switch self {
        case .under: return Theme.inkSoft
        case .almost: return Theme.warn
        case .done: return Theme.good
        case .resting: return Theme.ember
        case .overcooked: return Theme.bad
        }
    }
}
