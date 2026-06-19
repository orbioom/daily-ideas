import Foundation
import SwiftUI

@Observable
final class CastEngine {
    func totalHoursListened(_ episodes: [PodcastEpisode]) -> Double {
        Double(episodes.filter { $0.isListened }.reduce(0) { $0 + $1.durationMinutes }) / 60.0
    }

    func totalEpisodesListened(_ episodes: [PodcastEpisode]) -> Int {
        episodes.filter { $0.isListened }.count
    }

    func genreBreakdown(_ shows: [PodcastShow]) -> [(genre: PodcastGenre, count: Int)] {
        let grouped = Dictionary(grouping: shows, by: { $0.genre })
        return grouped.map { ($0.key, $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    func monthlyListened(_ episodes: [PodcastEpisode]) -> [(month: String, count: Int)] {
        let cal = Calendar.current
        let now = Date()
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        var result: [(String, Int)] = []
        for i in (0..<6).reversed() {
            guard let monthDate = cal.date(byAdding: .month, value: -i, to: now) else { continue }
            let count = episodes.filter { ep in
                guard ep.isListened, let ld = ep.listenedDate else { return false }
                return cal.isDate(ld, equalTo: monthDate, toGranularity: .month)
            }.count
            result.append((fmt.string(from: monthDate), count))
        }
        return result
    }

    func listeningStreakDays(_ episodes: [PodcastEpisode]) -> Int {
        let cal = Calendar.current
        let listenedDays = Set(
            episodes.compactMap { $0.isListened ? $0.listenedDate : nil }
                .map { cal.startOfDay(for: $0) }
        ).sorted(by: >)

        var streak = 0
        var current = cal.startOfDay(for: Date())
        for day in listenedDays {
            if day == current {
                streak += 1
                current = cal.date(byAdding: .day, value: -1, to: current) ?? current
            } else if day < current {
                break
            }
        }
        return streak
    }

    func topShows(_ shows: [PodcastShow]) -> [PodcastShow] {
        shows.sorted { $0.listenedCount > $1.listenedCount }.prefix(5).map { $0 }
    }
}

enum CastSettings {
    static let onboardingDone = "cast_onboarding_v1"
    static let defaultDuration = "cast_default_duration"
    static let sortOrder = "cast_sort_order"
    static let showRatings = "cast_show_ratings"
}
