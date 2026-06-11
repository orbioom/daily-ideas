import Foundation
import SwiftData

enum MediaType: String, Codable, CaseIterable {
    case movie = "Movie"
    case show = "TV Show"
}

enum WatchStatus: String, Codable, CaseIterable {
    case watchlist = "Watchlist"
    case watching = "Watching"
    case watched = "Watched"

    var icon: String {
        switch self {
        case .watchlist: return "bookmark.fill"
        case .watching:  return "play.circle.fill"
        case .watched:   return "checkmark.circle.fill"
        }
    }
}

enum MediaGenre: String, Codable, CaseIterable {
    case action = "Action"
    case comedy = "Comedy"
    case drama = "Drama"
    case thriller = "Thriller"
    case horror = "Horror"
    case sciFi = "Sci-Fi"
    case fantasy = "Fantasy"
    case romance = "Romance"
    case documentary = "Documentary"
    case animation = "Animation"
    case crime = "Crime"
    case adventure = "Adventure"
    case other = "Other"
}

@Model
final class MediaEntry {
    var id: UUID
    var title: String
    var mediaTypeRaw: String
    var year: Int
    var genreRaw: String
    var posterEmoji: String
    var statusRaw: String
    var rating: Double
    var notes: String
    var watchedDate: Date?
    var addedDate: Date
    var runtimeMinutes: Int

    @Relationship(deleteRule: .cascade, inverse: \Season.entry)
    var seasons: [Season]

    init(
        title: String,
        mediaType: MediaType,
        year: Int,
        genre: MediaGenre,
        posterEmoji: String,
        status: WatchStatus = .watchlist,
        rating: Double = 0,
        notes: String = "",
        watchedDate: Date? = nil,
        runtimeMinutes: Int = 90
    ) {
        self.id = UUID()
        self.title = title
        self.mediaTypeRaw = mediaType.rawValue
        self.year = year
        self.genreRaw = genre.rawValue
        self.posterEmoji = posterEmoji
        self.statusRaw = status.rawValue
        self.rating = rating
        self.notes = notes
        self.watchedDate = watchedDate
        self.addedDate = Date()
        self.runtimeMinutes = runtimeMinutes
        self.seasons = []
    }

    var mediaType: MediaType {
        MediaType(rawValue: mediaTypeRaw) ?? .movie
    }

    var genre: MediaGenre {
        MediaGenre(rawValue: genreRaw) ?? .other
    }

    var status: WatchStatus {
        WatchStatus(rawValue: statusRaw) ?? .watchlist
    }

    var totalEpisodes: Int {
        seasons.reduce(0) { $0 + $1.episodes.count }
    }

    var watchedEpisodes: Int {
        seasons.reduce(0) { $0 + $1.episodes.filter(\.watched).count }
    }

    var watchProgress: Double {
        guard totalEpisodes > 0 else { return 0 }
        return Double(watchedEpisodes) / Double(totalEpisodes)
    }

    var displayRuntime: String {
        if mediaType == .movie {
            let h = runtimeMinutes / 60
            let m = runtimeMinutes % 60
            if h > 0 { return "\(h)h \(m)m" }
            return "\(m)m"
        } else {
            return "\(totalEpisodes) ep"
        }
    }

    var totalWatchedMinutes: Int {
        if mediaType == .movie && status == .watched {
            return runtimeMinutes
        } else {
            return watchedEpisodes * runtimeMinutes
        }
    }
}
