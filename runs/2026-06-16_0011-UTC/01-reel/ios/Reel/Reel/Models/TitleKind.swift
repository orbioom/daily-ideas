import Foundation

/// Whether a tracked Title is a film or a TV show. Stored on `Title` as raw string.
enum TitleKind: String, CaseIterable, Identifiable {
    case movie = "Movie"
    case tvShow = "TV Show"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var systemImage: String {
        switch self {
        case .movie: return "film"
        case .tvShow: return "tv"
        }
    }

    var isShow: Bool { self == .tvShow }
}
