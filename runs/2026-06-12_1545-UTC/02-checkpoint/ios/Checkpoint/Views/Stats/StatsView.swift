import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var games: [Game]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()
                if games.isEmpty {
                    EmptyStateView(symbol: "chart.pie",
                                   title: "No stats yet",
                                   message: "Add games to your library to see your collection, time and spending come to life.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            headlineGrid
                            statusCard
                            genreCard
                            valueCard
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }

    private var headlineGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MiniStat(value: "\(games.count)", label: "Games")
            MiniStat(value: Fmt.hours(BacklogEngine.totalHoursPlayed(games)), label: "Played")
            MiniStat(value: "\(Int(BacklogEngine.completionRate(games) * 100))%", label: "Completion", tint: Theme.gold)
            MiniStat(value: "\(BacklogEngine.pileSize(games))", label: "In the pile")
            MiniStat(value: Fmt.hours(BacklogEngine.pileHoursRemaining(games)), label: "Pile hours")
            MiniStat(value: ratingText, label: "Avg rating", tint: Theme.gold)
        }
        .cpCard()
    }

    private var ratingText: String {
        if let r = BacklogEngine.averageRating(games) { return String(format: "%.1f", r) }
        return "—"
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Library by status").font(.headline).foregroundStyle(Theme.textPrimary)
            let data = BacklogEngine.byStatus(games)
            Chart(data) { item in
                SectorMark(
                    angle: .value("Count", item.count),
                    innerRadius: .ratio(0.58),
                    angularInset: 2
                )
                .cornerRadius(4)
                .foregroundStyle(item.status.tint)
            }
            .frame(height: 200)
            .accessibilityLabel("Donut chart of games by status")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(data) { item in
                    HStack(spacing: 6) {
                        Circle().fill(item.status.tint).frame(width: 9, height: 9)
                        Text(item.status.label).font(.caption).foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text("\(item.count)").font(.caption.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                    }
                }
            }
        }
        .cpCard()
    }

    private var genreCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your taste").font(.headline).foregroundStyle(Theme.textPrimary)
            let data = Array(BacklogEngine.byGenre(games).prefix(6))
            if data.isEmpty {
                Text("Add some owned games to see your genres.").font(.caption).foregroundStyle(Theme.textSecondary)
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Genre", item.genre.rawValue)
                    )
                    .foregroundStyle(Theme.heroGradient)
                    .cornerRadius(5)
                    .annotation(position: .trailing) {
                        Text("\(item.count)").font(.caption2).foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(height: CGFloat(data.count) * 38 + 20)
                .accessibilityLabel("Bar chart of games by genre")
            }
        }
        .cpCard()
    }

    private var valueCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Time & money").font(.headline).foregroundStyle(Theme.textPrimary)
            DetailRow(label: "Total spent", value: Currency.string(BacklogEngine.totalSpend(games)))
            Divider().overlay(Theme.track)
            if let cph = BacklogEngine.costPerHour(games) {
                DetailRow(label: "Cost per hour played", value: Currency.string(cph))
                Divider().overlay(Theme.track)
                Text(cphMessage(cph)).font(.caption).foregroundStyle(Theme.textSecondary)
            } else {
                DetailRow(label: "Cost per hour played", value: "—")
            }
        }
        .cpCard()
    }

    private func cphMessage(_ cph: Double) -> String {
        if cph < 1 { return "Outstanding value — under a buck an hour of play." }
        if cph < 3 { return "Great value for the hours you're getting." }
        if cph < 6 { return "Solid value across your collection." }
        return "Your backlog is where the value is hiding — play more of what you own!"
    }
}
