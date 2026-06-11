import Foundation
import SwiftData

@Model
final class Season {
    var seasonNumber: Int
    var entry: MediaEntry?

    @Relationship(deleteRule: .cascade, inverse: \Episode.season)
    var episodes: [Episode]

    init(seasonNumber: Int) {
        self.seasonNumber = seasonNumber
        self.episodes = []
    }

    var watchedEpisodes: Int { episodes.filter(\.watched).count }
    var totalEpisodes: Int { episodes.count }
    var isFullyWatched: Bool { totalEpisodes > 0 && watchedEpisodes == totalEpisodes }
}
