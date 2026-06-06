import SwiftUI

/// The role a segment plays in a routine. Drives color, default label, and haptic intent.
/// Stored as a raw `String` on `Segment` for tolerant decoding.
enum SegmentKind: String, CaseIterable, Identifiable, Codable {
    case prepare
    case work
    case rest
    case cooldown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .prepare:  return "Prepare"
        case .work:     return "Work"
        case .rest:     return "Rest"
        case .cooldown: return "Cooldown"
        }
    }

    /// SF Symbol used in lists and the run screen.
    var symbol: String {
        switch self {
        case .prepare:  return "hourglass"
        case .work:     return "bolt.fill"
        case .rest:     return "pause.fill"
        case .cooldown: return "wind"
        }
    }

    /// On-brand tint. Work is the restrained green (the "active" tone); others stay calm.
    var tint: Color {
        switch self {
        case .prepare:  return Brand.text2
        case .work:     return Brand.live
        case .rest:     return Brand.rest
        case .cooldown: return Brand.magic
        }
    }

    /// A sensible default duration (seconds) when adding this kind of segment.
    var defaultDuration: Int {
        switch self {
        case .prepare:  return 15
        case .work:     return 40
        case .rest:     return 20
        case .cooldown: return 60
        }
    }
}
