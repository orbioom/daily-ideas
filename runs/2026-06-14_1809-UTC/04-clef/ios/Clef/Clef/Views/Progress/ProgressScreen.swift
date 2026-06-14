import SwiftUI
import SwiftData
import Charts

/// Progress: mastery heatmap, accuracy/speed charts, and session history.
struct ProgressScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \DrillSession.date, order: .reverse) private var sessions: [DrillSession]
    @Query private var stats: [NoteStat]

    @State private var snapshot: ProgressSnapshot = .empty
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if isLoading {
                    loadingView
                } else if snapshot.totalSessions == 0 {
                    EmptyStateView(symbol: "chart.bar",
                                   title: "No practice yet",
                                   message: "Finish a drill and your accuracy, speed, and per-note mastery will appear here.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            summaryCard
                            accuracyChart
                            speedChart
                            masterySection
                            historyCard
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Progress")
            .task(id: sessions.count) { await recompute() }
            .task(id: stats.count) { await recompute() }
        }
    }

    @MainActor private func recompute() async {
        isLoading = true
        let snap = ProgressStats.compute(sessions: sessions, stats: stats)
        try? await Task.sleep(nanoseconds: 200_000_000)
        snapshot = snap
        isLoading = false
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView().controlSize(.large)
            Text("Crunching your practice…")
                .font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Computing progress")
    }

    // MARK: Summary

    private var summaryCard: some View {
        CardSection("Overview") {
            let cols = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: cols, spacing: 14) {
                tile("\(snapshot.totalSessions)", "Drills", "checklist")
                tile("\(snapshot.totalNotes)", "Notes read", "music.note")
                tile("\(Int(snapshot.overallAccuracy * 100))%", "Accuracy", "target")
                tile("\(snapshot.bestStreak)", "Best streak", "flame.fill")
            }
        }
    }

    private func tile(_ value: String, _ label: String, _ symbol: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: symbol).font(.system(size: 16)).foregroundStyle(Theme.accent)
            Text(value).font(Theme.rounded(22, .bold)).foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(Theme.rounded(11)).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: Charts

    private var accuracyChart: some View {
        CardSection("Accuracy over sessions") {
            Chart(snapshot.sessionPoints) { p in
                LineMark(x: .value("Session", p.index),
                         y: .value("Accuracy", p.accuracy))
                    .foregroundStyle(Theme.accent)
                    .interpolationMethod(.catmullRom)
                PointMark(x: .value("Session", p.index),
                          y: .value("Accuracy", p.accuracy))
                    .foregroundStyle(Theme.accent)
                    .symbolSize(28)
                    .accessibilityLabel("Session \(p.index)")
                    .accessibilityValue("\(Int(p.accuracy * 100)) percent")
            }
            .chartYScale(domain: 0...1)
            .chartYAxis {
                AxisMarks(values: [0, 0.5, 1.0]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let d = value.as(Double.self) {
                            Text("\(Int(d * 100))%").font(Theme.rounded(9))
                        }
                    }
                }
            }
            .frame(height: 170)
        }
    }

    private var speedChart: some View {
        CardSection("Average response time") {
            Chart(snapshot.sessionPoints) { p in
                LineMark(x: .value("Session", p.index),
                         y: .value("Seconds", p.avgMs / 1000))
                    .foregroundStyle(Theme.good)
                    .interpolationMethod(.catmullRom)
                    .accessibilityLabel("Session \(p.index)")
                    .accessibilityValue(String(format: "%.1f seconds", p.avgMs / 1000))
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let d = value.as(Double.self) {
                            Text(String(format: "%.0fs", d)).font(Theme.rounded(9))
                        }
                    }
                }
            }
            .frame(height: 150)
        }
    }

    // MARK: Mastery heatmap

    private var masterySection: some View {
        let clefs = Clef.allCases.filter { (snapshot.masteryByClef[$0]?.isEmpty == false) }
        return Group {
            if clefs.isEmpty {
                CardSection("Note mastery") {
                    Text("Answer a few notes to build your mastery map.")
                        .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                }
            } else {
                ForEach(clefs) { clef in
                    masteryCard(clef)
                }
            }
        }
    }

    private func masteryCard(_ clef: Clef) -> some View {
        let cells = snapshot.masteryByClef[clef] ?? []
        let columns = [GridItem(.adaptive(minimum: 52), spacing: 8)]
        return CardSection("\(clef.displayName) mastery") {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(cells) { cell in
                    VStack(spacing: 4) {
                        Text(Pitch.displayLetter(cell.letter, solfege: settings.noteNameStyle.useSolfege))
                            .font(Theme.rounded(13, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("\(Int(cell.mastery * 100))%")
                            .font(Theme.rounded(10))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(masteryColor(cell.mastery, seen: cell.seen))
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(cell.letter): \(Int(cell.mastery * 100)) percent mastery over \(cell.seen) tries")
                }
            }
        }
    }

    private func masteryColor(_ mastery: Double, seen: Int) -> Color {
        guard seen > 0 else { return Theme.surfaceAlt }
        return Theme.accent.opacity(0.18 + 0.55 * mastery)
    }

    // MARK: History

    private var historyCard: some View {
        CardSection("Recent drills") {
            VStack(spacing: 0) {
                ForEach(Array(sessions.prefix(12))) { s in
                    historyRow(s)
                    if s.id != sessions.prefix(12).last?.id {
                        Divider().overlay(Theme.hairline)
                    }
                }
            }
        }
    }

    private func historyRow(_ s: DrillSession) -> some View {
        HStack(spacing: 12) {
            Image(systemName: s.mode == .timed ? "timer" : "music.note.list")
                .foregroundStyle(Theme.accent)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(s.clef.displayName) · \(s.mode.label)")
                    .font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.ink)
                Text(s.date.formatted(date: .abbreviated, time: .shortened))
                    .font(Theme.rounded(11)).foregroundStyle(Theme.inkFaint)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(s.accuracy * 100))%")
                    .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink).monospacedDigit()
                Text("\(s.correct)/\(s.total)")
                    .font(Theme.rounded(11)).foregroundStyle(Theme.inkSoft)
            }
        }
        .padding(.vertical, 9)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(s.clef.displayName) \(s.mode.label), \(Int(s.accuracy * 100)) percent, \(s.correct) of \(s.total)")
    }
}
