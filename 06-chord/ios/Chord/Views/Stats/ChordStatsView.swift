import SwiftUI
import SwiftData
import Charts

struct ChordStatsView: View {
    @Query(sort: \Progression.createdDate, order: .reverse) private var progressions: [Progression]
    @State private var engine = ChordEngine()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if progressions.isEmpty {
                        ContentUnavailableView {
                            Label("No Progressions Yet", systemImage: "chart.bar.fill")
                        } description: {
                            Text("Create progressions to see your stats here.")
                        }
                    } else {
                        summaryRow
                        weeklyChart
                        genreChart
                        recentList
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
            statCard("music.note.list",
                     value: "\(engine.totalProgressions(progressions))",
                     label: "Progressions",
                     color: ChordTheme.teal)
            statCard("star.fill",
                     value: "\(engine.favoriteCount(progressions))",
                     label: "Favorites",
                     color: .yellow)
            statCard("squares.leading.rectangle",
                     value: String(format: "%.1f", engine.averageChordsPerProgression(progressions)),
                     label: "Avg Chords",
                     color: ChordTheme.amber)
        }
    }

    private func statCard(_ icon: String, value: String, label: String, color: Color) -> some View {
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

    private var weeklyChart: some View {
        let data = engine.weeklyActivity(progressions)
        return VStack(alignment: .leading, spacing: 8) {
            Text("This Week — New Progressions")
                .font(.headline)
            Chart(data) { item in
                BarMark(x: .value("Day", item.day), y: .value("Count", item.count))
                    .foregroundStyle(ChordTheme.teal.gradient)
                    .cornerRadius(5)
            }
            .frame(height: 140)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityLabel("Weekly progression activity bar chart")
    }

    private var genreChart: some View {
        let data = engine.genreBreakdown(progressions)
        guard !data.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(VStack(alignment: .leading, spacing: 8) {
            Text("By Genre")
                .font(.headline)
            Chart(data) { item in
                BarMark(x: .value("Genre", item.genre), y: .value("Count", item.count))
                    .foregroundStyle(by: .value("Genre", item.genre))
                    .cornerRadius(5)
            }
            .frame(height: 120)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityLabel("Progressions by genre bar chart"))
    }

    private var recentList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Progressions")
                .font(.headline)
            ForEach(progressions.prefix(6)) { p in
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(ChordTheme.genreColor(p.genre).opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: p.genre.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(ChordTheme.genreColor(p.genre))
                    }
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(p.title)
                            .font(.subheadline)
                            .lineLimit(1)
                        Text(p.chordSummary.isEmpty ? "No chords yet" : p.chordSummary)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(p.keyName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(ChordTheme.teal)
                        Text(p.createdDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}
