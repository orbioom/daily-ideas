import SwiftUI
import SwiftData
import Charts

struct ProgressDashboardView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PracticeSession.date, order: .reverse) private var sessions: [PracticeSession]

    private var stats: PracticeStats { PracticeStats.from(sessions) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if sessions.isEmpty {
                    EmptyStateView(icon: "chart.bar.fill",
                                   title: "No practice yet",
                                   message: "Run a fretboard drill or a one-minute change round and your progress will land here.")
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            statsGrid
                            cpmChart
                            accuracyChart
                            recentList
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(value: "\(stats.currentStreak)", label: "Day streak")
            StatTile(value: "\(stats.totalMinutes)m", label: "Practised", accent: Theme.good)
            StatTile(value: "\(stats.totalSessions)", label: "Sessions", accent: Theme.ink)
            StatTile(value: stats.bestCPM > 0 ? "\(stats.bestCPM)" : "—", label: "Best CPM")
            StatTile(value: stats.bestAccuracy > 0 ? "\(Int(stats.bestAccuracy * 100))%" : "—",
                     label: "Best accuracy", accent: Theme.good)
            StatTile(value: "\(stats.longestStreak)", label: "Longest streak", accent: Theme.ink)
        }
    }

    private var changeSessions: [PracticeSession] {
        sessions.filter { $0.kind == .changes }.sorted { $0.date < $1.date }.suffix(20)
    }
    private var fretSessions: [PracticeSession] {
        sessions.filter { $0.kind == .fretboard }.sorted { $0.date < $1.date }.suffix(20)
    }

    @ViewBuilder private var cpmChart: some View {
        if !changeSessions.isEmpty {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Changes per minute", systemImage: "metronome.fill")
                        .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                    Chart(changeSessions) { s in
                        LineMark(x: .value("Date", s.date), y: .value("CPM", s.primaryMetric))
                            .foregroundStyle(Theme.accent)
                            .interpolationMethod(.catmullRom)
                        PointMark(x: .value("Date", s.date), y: .value("CPM", s.primaryMetric))
                            .foregroundStyle(Theme.accent)
                    }
                    .frame(height: 160)
                    .chartYAxis { AxisMarks(position: .leading) }
                }
            }
        }
    }

    @ViewBuilder private var accuracyChart: some View {
        if !fretSessions.isEmpty {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Fretboard accuracy", systemImage: "guitars.fill")
                        .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                    Chart(fretSessions) { s in
                        BarMark(x: .value("Date", s.date, unit: .day),
                                y: .value("Accuracy", Int(s.accuracy * 100)))
                            .foregroundStyle(Theme.good)
                    }
                    .frame(height: 160)
                    .chartYScale(domain: 0...100)
                    .chartYAxis { AxisMarks(position: .leading) }
                }
            }
        }
    }

    private var recentList: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent sessions").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                let recent = Array(sessions.prefix(12))
                ForEach(Array(recent.enumerated()), id: \.offset) { idx, s in
                    HStack(spacing: 12) {
                        Image(systemName: s.kind == .changes ? "metronome.fill" : "guitars.fill")
                            .foregroundStyle(Theme.accent).frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.label).font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                            Text(Fmt.relativeDay(s.date)).font(Theme.rounded(12, .regular)).foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Text(s.kind == .changes ? "\(s.primaryMetric) CPM" : "\(s.primaryMetric)/\(s.secondaryMetric)")
                            .font(Theme.rounded(14, .bold)).foregroundStyle(Theme.inkSoft)
                    }
                    .accessibilityElement(children: .combine)
                    if idx < recent.count - 1 { Divider().background(Theme.hairline) }
                }
            }
        }
    }
}
