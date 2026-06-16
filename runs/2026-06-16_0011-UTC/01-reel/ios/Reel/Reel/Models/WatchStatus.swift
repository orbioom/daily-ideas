import SwiftUI

/// Where a Title sits in your watching journey. Stored on `Title` as raw string.
enum WatchStatus: String, CaseIterable, Identifiable {
    case watchlist = "Watchlist"
    case watching = "Watching"
    case watched = "Watched"
    case abandoned = "Abandoned"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var systemImage: String {
        switch self {
        case .watchlist: return "bookmark"
        case .watching: return "play.circle"
        case .watched: return "checkmark.circle"
        case .abandoned: return "xmark.circle"
        }
    }

    var tint: Color {
        switch self {
        case .watchlist: return Theme.inkSoft
        case .watching: return Theme.accent
        case .watched: return Theme.good
        case .abandoned: return Theme.bad
        }
    }
}
