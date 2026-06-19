import SwiftUI
import SwiftData
import Charts

struct CastStatsView: View {
    @Query private var shows: [PodcastShow]
    @Query private var allEps: [PodcastEpisode]
    @State private var engine = CastEngine()

    private var listenedEps: [PodcastEpisode] { allEps.filter { $0.isListened } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if shows.isEmpty {
                        ContentUnavailableView {
                            Label("No Stats Yet", systemImage: "chart.bar")
                        } description: {
                            Text("Add shows and log episodes to see your listening stats.")
                        }
                    } else {
                        summaryRow
                        monthlyChart
                        genreChart
                        topShowsList
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            statCard(
                icon: "headphones",
                value: "\(engine.totalEpisodesListened(allEps))",
                label: "Listened",
                color: .green
            )
            statCard(
                icon: "clock.fill",
                value: String(format: "%.0f", engine.totalHoursListened(allEps)),
                label: "Hours",
                color: CastTheme.purple
            )
            statCard(
                icon: "mic.circle.fill",
                value: "\(shows.count)",
                label: "Shows",
                color: CastTheme.amber
            )
        }
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundStyle(color).accessibilityHidden(true)
            Text(value).font(.system(size: 20, weight: .bold, design: .rounded))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var monthlyChart: some View {
        let data = engine.monthlyListened(allEps)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Episodes Listened")
                .font(.headline)
            Chart(data, id: \.month) { item in
                BarMark(x: .value("Month", item.month), y: .value("Episodes", item.count))
                    .foregroundStyle(CastTheme.purple.gradient)
                    .cornerRadius(4)
            }
            .frame(height: 140)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityLabel("Monthly episodes listened bar chart")
    }

    private var genreChart: some View {
        let data = engine.genreBreakdown(shows)
        guard !data.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                Text("Shows by Genre")
                    .font(.headline)
                Chart(data, id: \.genre) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Genre", item.genre.rawValue))
                    .cornerRadius(4)
                }
                .frame(height: 160)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .accessibilityLabel("Shows by genre donut chart")
        )
    }

    private var topShowsList: some View {
        let top = engine.topShows(shows)
        guard !top.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                Text("Most Listened")
                    .font(.headline)
                ForEach(Array(top.enumerated()), id: \.element.id) { idx, show in
                    HStack(spacing: 12) {
                        Text("\(idx + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 18)
                        ShowArtwork(show: show, size: 36)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(show.title).font(.subheadline).lineLimit(1)
                            Text("\(show.listenedCount) ep\(show.listenedCount == 1 ? "" : "s")")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
            }
        )
    }
}
