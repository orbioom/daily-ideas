import SwiftUI
import SwiftData
import Charts

/// Stats dashboard: win-rate bars per difficulty, headline numbers, recent
/// history. Empty state before any games. Pro can export CSV.
struct StatsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \GameRecord.date, order: .reverse) private var records: [GameRecord]

    @State private var showPaywall = false
    @State private var exportText: String?
    @State private var showExport = false

    private var byDifficulty: [DifficultyStats] {
        StatsCalculator.byDifficulty(records).filter { $0.played > 0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if records.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 18) {
                        headlineCard
                        winRateCard
                        timesCard
                        historyCard
                        exportButton
                    }
                    .padding(20)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Stats")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showExport) {
                if let exportText {
                    ExportSheet(text: exportText)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack {
            EmptyStateView(systemImage: "chart.bar.xaxis",
                           title: "No games yet",
                           message: "Play a few rounds and your win rate, best times and streaks will appear here.")
        }
        .frame(maxWidth: .infinity, minHeight: 420)
    }

    // MARK: - Headline

    private var headlineCard: some View {
        GlassCard {
            HStack(spacing: 8) {
                StatChip(label: "Played", value: "\(StatsCalculator.totalPlayed(records))")
                StatChip(label: "Win rate",
                         value: "\(Int((StatsCalculator.overallWinRate(records) * 100).rounded()))%",
                         tint: Theme.accent)
                StatChip(label: "Streak",
                         value: "\(StatsCalculator.currentWinStreak(records))",
                         tint: Theme.good)
                StatChip(label: "Best run",
                         value: "\(StatsCalculator.bestWinStreak(records))")
            }
        }
    }

    // MARK: - Win rate chart

    private var winRateCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Win rate by difficulty")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                Chart(byDifficulty) { stat in
                    BarMark(
                        x: .value("Difficulty", stat.difficulty.title),
                        y: .value("Win rate", stat.winRate * 100)
                    )
                    .foregroundStyle(Theme.accent.gradient)
                    .cornerRadius(6)
                    .annotation(position: .top) {
                        Text("\(Int((stat.winRate * 100).rounded()))%")
                            .font(Theme.rounded(11, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .chartYScale(domain: 0.0...100.0)
                .chartYAxis {
                    AxisMarks(values: [0.0, 50.0, 100.0]) { value in
                        AxisGridLine().foregroundStyle(Theme.hairline)
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))%").font(Theme.rounded(10))
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
    }

    // MARK: - Times

    private var timesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Best & average times")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                ForEach(byDifficulty) { stat in
                    HStack {
                        Text(stat.difficulty.title)
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(stat.bestTime.map { "Best \(Formatters.clock($0))" } ?? "No win yet")
                                .font(Theme.mono(13, .semibold))
                                .foregroundStyle(stat.bestTime == nil ? Theme.inkFaint : Theme.accent)
                            if let avg = stat.avgTime {
                                Text("Avg \(Formatters.clock(avg)) · \(stat.won)/\(stat.played)")
                                    .font(Theme.rounded(12))
                                    .foregroundStyle(Theme.inkSoft)
                            } else {
                                Text("\(stat.won)/\(stat.played) won")
                                    .font(Theme.rounded(12))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    if stat.id != byDifficulty.last?.id {
                        Divider().overlay(Theme.hairline)
                    }
                }
            }
        }
    }

    // MARK: - History

    private var historyCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent games")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                ForEach(records.prefix(15)) { rec in
                    HStack(spacing: 10) {
                        Image(systemName: rec.won ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(rec.won ? Theme.good : Theme.bad)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(recordTitle(rec))
                                    .font(Theme.rounded(15, .semibold))
                                    .foregroundStyle(Theme.ink)
                                if rec.noGuess {
                                    TagPill(text: "NG", tint: Theme.good)
                                }
                            }
                            Text(rec.date.formatted(date: .abbreviated, time: .shortened))
                                .font(Theme.rounded(12))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Text(Formatters.clock(rec.durationSec))
                            .font(Theme.mono(14, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .padding(.vertical, 4)
                    if rec.id != records.prefix(15).last?.id {
                        Divider().overlay(Theme.hairline)
                    }
                }
            }
        }
    }

    private func recordTitle(_ rec: GameRecord) -> String {
        if rec.difficultyRaw == "daily" { return "Daily" }
        return "\(rec.difficulty.title) · \(rec.rows)×\(rec.cols)"
    }

    // MARK: - Export (Pro)

    private var exportButton: some View {
        Button {
            if isPro {
                exportText = makeCSV()
                showExport = true
            } else {
                showPaywall = true
            }
        } label: {
            HStack {
                Image(systemName: isPro ? "square.and.arrow.up" : "lock.fill")
                Text(isPro ? "Export stats as CSV" : "Export CSV (Pro)")
            }
            .font(Theme.rounded(15, .semibold))
            .foregroundStyle(Theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.accentSoft)
            )
        }
        .buttonStyle(.plain)
    }

    private func makeCSV() -> String {
        var lines = ["date,difficulty,rows,cols,mines,won,durationSec,noGuess"]
        let df = ISO8601DateFormatter()
        for r in records {
            let row = [
                df.string(from: r.date),
                r.difficultyRaw,
                "\(r.rows)", "\(r.cols)", "\(r.mines)",
                r.won ? "true" : "false",
                String(format: "%.1f", r.durationSec),
                r.noGuess ? "true" : "false"
            ].joined(separator: ",")
            lines.append(row)
        }
        return lines.joined(separator: "\n")
    }
}

/// Simple share sheet for the exported CSV text.
struct ExportSheet: View {
    let text: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(Theme.mono(12))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Stats CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: text) { Image(systemName: "square.and.arrow.up") }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [GameRecord.self, SavedGame.self, DailyResult.self], inMemory: true)
}
