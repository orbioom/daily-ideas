import SwiftUI

/// Whether a title is an anime (episodes) or a manga (chapters).
enum AnimeMediaKind: String, Codable, CaseIterable, Identifiable {
    case anime = "Anime"
    case manga = "Manga"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .anime: return "play.tv"
        case .manga: return "book"
        }
    }

    /// Noun for a single unit of progress.
    var unitNoun: String {
        switch self {
        case .anime: return "episode"
        case .manga: return "chapter"
        }
    }

    var unitNounPlural: String { unitNoun + "s" }

    /// Verb describing engagement, used in "Watching" / "Reading".
    var currentVerb: String {
        switch self {
        case .anime: return "Watching"
        case .manga: return "Reading"
        }
    }

    /// Rough minutes spent per unit, for time-spent estimates.
    var minutesPerUnit: Int {
        switch self {
        case .anime: return 24
        case .manga: return 5
        }
    }
}

/// Tracking status for a title.
enum WatchStatus: String, Codable, CaseIterable, Identifiable {
    case planning = "Planning"
    case current = "Current"
    case completed = "Completed"
    case onHold = "On Hold"
    case dropped = "Dropped"

    var id: String { rawValue }

    /// Status label adapted to the kind (Current → Watching / Reading).
    func label(for kind: AnimeMediaKind) -> String {
        switch self {
        case .current: return kind.currentVerb
        default: return rawValue
        }
    }

    var symbol: String {
        switch self {
        case .planning: return "bookmark"
        case .current: return "play.circle"
        case .completed: return "checkmark.seal"
        case .onHold: return "pause.circle"
        case .dropped: return "xmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .planning: return Theme.cyan
        case .current: return Theme.accent
        case .completed: return Theme.good
        case .onHold: return Theme.gold
        case .dropped: return Theme.inkFaint
        }
    }
}

/// Anime broadcast season.
enum AnimeSeason: String, Codable, CaseIterable, Identifiable {
    case winter = "Winter"
    case spring = "Spring"
    case summer = "Summer"
    case fall = "Fall"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .winter: return "snowflake"
        case .spring: return "leaf"
        case .summer: return "sun.max"
        case .fall: return "wind"
        }
    }

    /// Sort order within a year (winter earliest).
    var order: Int {
        switch self {
        case .winter: return 0
        case .spring: return 1
        case .summer: return 2
        case .fall: return 3
        }
    }
}
