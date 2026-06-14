import SwiftUI

enum Sentiment: String, Codable, CaseIterable, Identifiable {
    case loved = "Loved"
    case liked = "Liked"
    case okay = "Okay"

    var id: String { rawValue }

    /// Higher rank = better tier. Loved (2) > Liked (1) > Okay (0).
    var tierRank: Int {
        switch self {
        case .loved: return 2
        case .liked: return 1
        case .okay: return 0
        }
    }

    var color: Color {
        switch self {
        case .loved: return Color.dyn(0xD94F3D, 0xE8654F)
        case .liked: return Color.dyn(0xC9701B, 0xE6A45A)
        case .okay: return Color.dyn(0x6E5A50, 0xB29C90)
        }
    }

    var symbol: String {
        switch self {
        case .loved: return "heart.fill"
        case .liked: return "hand.thumbsup.fill"
        case .okay: return "minus.circle.fill"
        }
    }

    var blurb: String {
        switch self {
        case .loved: return "I'd go back in a heartbeat"
        case .liked: return "Solid, would return"
        case .okay: return "It was fine"
        }
    }
}
