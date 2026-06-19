import Foundation
import SwiftData

enum PodcastGenre: String, CaseIterable, Codable {
    case trueCrime = "True Crime"
    case comedy = "Comedy"
    case news = "News"
    case technology = "Technology"
    case society = "Society"
    case history = "History"
    case science = "Science"
    case business = "Business"
    case health = "Health"
    case arts = "Arts"
    case sports = "Sports"
    case education = "Education"
    case fiction = "Fiction"
    case other = "Other"

    var icon: String {
        switch self {
        case .trueCrime: return "magnifyingglass"
        case .comedy: return "face.smiling"
        case .news: return "newspaper"
        case .technology: return "cpu"
        case .society: return "person.3"
        case .history: return "clock.arrow.circlepath"
        case .science: return "atom"
        case .business: return "briefcase"
        case .health: return "heart"
        case .arts: return "paintpalette"
        case .sports: return "sportscourt"
        case .education: return "book"
        case .fiction: return "sparkles"
        case .other: return "square.grid.2x2"
        }
    }
}

enum ShowStatus: String, CaseIterable, Codable {
    case active = "Active"
    case finished = "Finished"
    case paused = "Paused"
}

@Model
final class PodcastShow {
    var id: UUID
    var title: String
    var host: String
    var genre: PodcastGenre
    var status: ShowStatus
    var rating: Int
    var notes: String
    var addedDate: Date
    var accentColorHex: String
    @Relationship(deleteRule: .cascade) var episodes: [PodcastEpisode]

    init(
        title: String,
        host: String = "",
        genre: PodcastGenre = .other,
        status: ShowStatus = .active,
        rating: Int = 0,
        notes: String = "",
        accentColorHex: String = "#6040B4"
    ) {
        self.id = UUID()
        self.title = title
        self.host = host
        self.genre = genre
        self.status = status
        self.rating = rating
        self.notes = notes
        self.addedDate = Date()
        self.accentColorHex = accentColorHex
        self.episodes = []
    }

    var listenedCount: Int { episodes.filter { $0.isListened }.count }
    var totalEpisodes: Int { episodes.count }
    var totalMinutesListened: Int {
        episodes.filter { $0.isListened }.reduce(0) { $0 + $1.durationMinutes }
    }
    var unlistenedCount: Int { episodes.filter { !$0.isListened && $0.isInQueue }.count }
}
