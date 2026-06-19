import Foundation
import SwiftData

@Model
final class PodcastEpisode {
    var id: UUID
    var title: String
    var episodeNumber: Int
    var seasonNumber: Int
    var durationMinutes: Int
    var publishedDate: Date?
    var listenedDate: Date?
    var isListened: Bool
    var isInQueue: Bool
    var rating: Int
    var notes: String
    var show: PodcastShow?

    init(
        title: String,
        episodeNumber: Int = 0,
        seasonNumber: Int = 0,
        durationMinutes: Int = 30,
        publishedDate: Date? = nil,
        isListened: Bool = false,
        isInQueue: Bool = false,
        rating: Int = 0,
        notes: String = ""
    ) {
        self.id = UUID()
        self.title = title
        self.episodeNumber = episodeNumber
        self.seasonNumber = seasonNumber
        self.durationMinutes = durationMinutes
        self.publishedDate = publishedDate
        self.listenedDate = nil
        self.isListened = isListened
        self.isInQueue = isInQueue
        self.rating = rating
        self.notes = notes
    }

    var durationFormatted: String {
        let h = durationMinutes / 60
        let m = durationMinutes % 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m) min"
    }

    var episodeLabel: String {
        if episodeNumber > 0 && seasonNumber > 0 {
            return "S\(seasonNumber) E\(episodeNumber)"
        } else if episodeNumber > 0 {
            return "Ep \(episodeNumber)"
        }
        return ""
    }
}
