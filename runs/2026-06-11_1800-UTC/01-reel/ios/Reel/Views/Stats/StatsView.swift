import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var entries: [MediaEntry]

    private var watchedEntries: [MediaEntry] { entries.filter { $0.status == .watched } }
    private var watchingEntries: [MediaEntry] { entries.filter { $0.status == .watching } }
    private var watchlistEntries: [MediaEntry] { entries.filter { $0.status == .watchlist } }

    private var totalMinutes: Int { entries.reduce(0) { $0 + $1.totalWatchedMinutes } }
    private var totalHours: Double { Double(totalMinutes) / 60.0 }
    private var totalMovies: Int { entries.filter { $0.mediaType == .movie && $0.status == .watched }.count }
    private var totalShows: Int { entries.filter { $0.mediaType == .show && $0.status == .watched }.count }

    private var genreCounts: [(genre: String, count: Int)] {
        let all = entries.filter { $0.status == .watched }
        var counts: [String: Int] = [:]
        for e in all { counts[e.genre.rawValue, default: 0] += 1 }
        return counts.map { (genre: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    private var ratingDistribution: [(stars: String, count: Int)] {
        let rated = entries.filter { $0.rating > 0 }
        var dist: [Int: Int] = [:]
        for e in rated { dist[Int(e.rating.rounded()), default: 0] += 1 }
        return (1...5).map { star in
            (stars: "\(star)★", count: dist[star] ?? 0)
        }
    }

    private var decadeCounts: [(decade: String, count: Int)] {
        let all = entries.filter { $0.status == .watched }
        var counts: [Int: Int] = [:]
        for e in all {
            let d = (e.year / 10) * 10
            counts[d, default: 0] += 1
        }
        return counts.map { (decade: "\($0.key)s", count: $0.value) }
            .sorted { $0.decade < $1.decade }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if entries.isEmpty {
                        EmptyStateView(
                            icon: "chart.bar.fill",
                            title: "No stats yet",
                            subtitle: "Add movies and shows to your library to see your viewing stats."
                        )
                        .frame(minHeight: 400)
                    } else {
                        overviewCards
                        if !genreCounts.isEmpty { genreChart }
                        if ratingDistribution.contains(where: { $0.count > 0 }) { ratingChart }
                        if !decadeCounts.isEmpty { decadeChart }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 80)
            }
            .background(Theme.bgPrimary)
            .navigationTitle("Stats")
        }
    }

    @ViewBuilder
    private var overviewCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(value: "\(watchedEntries.count)", label: "Titles Watched", icon: "checkmark.circle.fill", color: .green)
            StatCard(value: String(format: "%.0f", totalHours), label: "Hours Watched", icon: "clock.fill", color: Theme.gold)
            StatCard(value: "\(totalMovies)", label: "Movies", icon: "film.fill", color: .blue)
            StatCard(value: "\(totalShows)", label: "TV Shows", icon: "tv.fill", color: .purple)
            StatCard(value: "\(watchingEntries.count)", label: "Currently Watching", icon: "play.circle.fill", color: .orange)
            StatCard(value: "\(watchlistEntries.count)", label: "On Watchlist", icon: "bookmark.fill", color: Theme.silver)
        }
    }

    @ViewBuilder
    private var genreChart: some View {
        ChartCard(title: "Top Genres") {
            Chart(genreCounts.prefix(6), id: \.genre) { item in
                BarMark(
                    x: .value("Count", item.count),
                    y: .value("Genre", item.genre)
                )
                .foregroundStyle(Theme.gold.gradient)
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("\(item.count)")
                        .font(.caption2)
                        .foregroundStyle(Theme.silver)
                }
            }
            .chartXAxis(.hidden)
            .frame(height: CGFloat(min(genreCounts.prefix(6).count, 6)) * 36 + 20)
        }
    }

    @ViewBuilder
    private var ratingChart: some View {
        ChartCard(title: "Your Ratings") {
            Chart(ratingDistribution, id: \.stars) { item in
                BarMark(
                    x: .value("Stars", item.stars),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(Theme.gold.gradient)
                .cornerRadius(4)
            }
            .frame(height: 140)
        }
    }

    @ViewBuilder
    private var decadeChart: some View {
        ChartCard(title: "By Decade") {
            Chart(decadeCounts, id: \.decade) { item in
                BarMark(
                    x: .value("Decade", item.decade),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(Theme.silver.opacity(0.7).gradient)
                .cornerRadius(4)
            }
            .frame(height: 140)
        }
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.silver)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.bgSecondary, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

private struct ChartCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            content
        }
        .padding()
        .background(Theme.bgSecondary, in: RoundedRectangle(cornerRadius: 14))
    }
}
