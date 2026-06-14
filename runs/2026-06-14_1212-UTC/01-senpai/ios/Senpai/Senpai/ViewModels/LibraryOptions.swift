import SwiftUI

/// How the library grid is sorted.
enum LibrarySort: String, CaseIterable, Identifiable {
    case recent = "Recent"
    case score = "Score"
    case title = "Title"
    case progress = "Progress"
    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .recent: return "clock"
        case .score: return "star"
        case .title: return "textformat"
        case .progress: return "chart.bar"
        }
    }
}

/// Kind filter for the library segmented control.
enum KindFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case anime = "Anime"
    case manga = "Manga"
    var id: String { rawValue }

    /// Matching media kind, or nil for "All".
    var kind: AnimeMediaKind? {
        switch self {
        case .all: return nil
        case .anime: return .anime
        case .manga: return .manga
        }
    }

    var symbol: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .anime: return "play.tv"
        case .manga: return "book"
        }
    }
}

/// Status filter (optional) for the library.
enum StatusFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case planning = "Planning"
    case current = "Current"
    case completed = "Completed"
    case onHold = "On Hold"
    case dropped = "Dropped"
    var id: String { rawValue }

    var status: WatchStatus? {
        switch self {
        case .all: return nil
        case .planning: return .planning
        case .current: return .current
        case .completed: return .completed
        case .onHold: return .onHold
        case .dropped: return .dropped
        }
    }

    var label: String {
        switch self {
        case .all: return "All statuses"
        default: return rawValue
        }
    }
}

/// How vivid the gradient covers and accent fills render.
enum AccentIntensity: String, CaseIterable, Identifiable {
    case soft = "Soft"
    case standard = "Standard"
    case vivid = "Vivid"
    var id: String { rawValue }

    /// Saturation multiplier applied to cover gradients.
    var saturationScale: Double {
        switch self {
        case .soft: return 0.78
        case .standard: return 1.0
        case .vivid: return 1.18
        }
    }
}
