import Foundation
import SwiftData

@Model
final class Episode {
    var episodeNumber: Int
    var title: String
    var watched: Bool
    var watchedDate: Date?
    var season: Season?

    init(episodeNumber: Int, title: String = "") {
        self.episodeNumber = episodeNumber
        self.title = title.isEmpty ? "Episode \(episodeNumber)" : title
        self.watched = false
        self.watchedDate = nil
    }
}
