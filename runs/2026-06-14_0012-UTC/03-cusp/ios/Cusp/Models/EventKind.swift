import Foundation

/// Whether an event counts down to a future date ("until") or up from a past one ("since").
enum EventKind: String, CaseIterable, Identifiable {
    case until
    case since

    var id: String { rawValue }

    var title: String {
        switch self {
        case .until: return "Days Until"
        case .since: return "Days Since"
        }
    }

    var shortTitle: String {
        switch self {
        case .until: return "Until"
        case .since: return "Since"
        }
    }

    var verb: String {
        switch self {
        case .until: return "until"
        case .since: return "since"
        }
    }

    var symbol: String {
        switch self {
        case .until: return "arrow.forward.circle"
        case .since: return "arrow.backward.circle"
        }
    }
}
