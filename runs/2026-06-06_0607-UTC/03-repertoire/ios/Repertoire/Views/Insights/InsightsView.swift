import SwiftUI
import SwiftData

/// The insights tab: weekly minutes heatmap, current/longest streak, time-by-piece,
/// and the least-recently-practiced suggestion. All derived from real sessions.
struct InsightsView: View {
    @Environment(SettingsStore.self) private var settings
    @Query private var sessions: [PracticeSession]
    @Query private var pieces: [Piece]

    private var totalMinutes: Int { Insights.totalMinutes(sessions: sessions) }
    private var minutesThisWeek: Int { Insights.minutesThisWeek(sessions: sessions) }
    private var currentStreak: Int { Insights.currentStreak(sessions: sessions) }
    private var longestStreak: Int { Insights.longestStreak(sessions: sessions) }
    private var heatmap: [[(day: Date, minutes: Int)]] {
        Insights.weeklyHeatmap(sessions: sessions, weeks: 6)
    }
    private var byPiece: [(piece: Piece, minutes: Int)] { Insights.timeByPiece(pieces: pieces) }
    private var suggested: Piece? { Insights.suggestedNext(pieces: pieces) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if sessions.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar",
                        title: "No insights yet",
                        message: "Run a practice session and your streaks, weekly minutes, and time per piece will appear here."
                    )
                } else {
                    content
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                statsRow
                heatmapSection
                if let suggested { suggestionSection(suggested) }
                timeByPieceSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatTile(value: "\(currentStreak)",
                         label: currentStreak == 1 ? "day streak" : "day streak now",
                         systemImage: "flame")
                StatTile(value: "\(longestStreak)", label: "longest streak", systemImage: "trophy")
            }
            HStack(spacing: 12) {
                StatTile(value: "\(minutesThisWeek)", label: "min this week", systemImage: "calendar")
                StatTile(value: formatHours(totalMinutes), label: "total practiced", systemImage: "clock")
            }
        }
    }

    private func formatHours(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    // MARK: - Heatmap

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Weekly Minutes")
            GlassCard {
                HeatmapGrid(weeks: heatmap)
            }
        }
    }

    // MARK: - Suggestion

    private func suggestionSection(_ piece: Piece) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Suggested Next")
            NavigationLink {
                PieceDetailView(piece: piece)
            } label: {
                GlassCard {
                    HStack(spacing: 14) {
                        Image(systemName: "sparkle")
                            .font(.title2)
                            .foregroundStyle(Brand.magic)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(piece.title)
                                .font(.headline)
                                .foregroundStyle(Brand.text)
                            Text(Insights.lastPracticedPhrase(piece))
                                .font(.subheadline)
                                .foregroundStyle(Brand.text2)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text3)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint("Least recently practiced active piece. Opens its detail.")
        }
    }

    // MARK: - Time by piece

    private var timeByPieceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Time by Piece")
            if byPiece.isEmpty {
                GlassCard {
                    Text("No per-piece time recorded yet.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                let maxMinutes = max(1, byPiece.map { $0.minutes }.max() ?? 1)
                GlassCard {
                    VStack(spacing: 14) {
                        ForEach(byPiece, id: \.piece.id) { item in
                            TimeByPieceRow(title: item.piece.title,
                                           minutes: item.minutes,
                                           fraction: Double(item.minutes) / Double(maxMinutes))
                        }
                    }
                }
            }
        }
    }
}

/// A horizontal bar row: piece title, a proportional bar, and its minutes.
private struct TimeByPieceRow: View {
    var title: String
    var minutes: Int
    var fraction: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.text)
                    .lineLimit(1)
                Spacer()
                Text("\(minutes) min")
                    .font(Brand.mono(13))
                    .foregroundStyle(Brand.text2)
                    .monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Brand.text3.opacity(0.16))
                    Capsule()
                        .fill(Brand.live.opacity(0.7))
                        .frame(width: max(4, geo.size.width * min(1, max(0, fraction))))
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(minutes) minutes")
    }
}

#Preview {
    InsightsView()
        .environment(SettingsStore())
        .previewContainer()
}
