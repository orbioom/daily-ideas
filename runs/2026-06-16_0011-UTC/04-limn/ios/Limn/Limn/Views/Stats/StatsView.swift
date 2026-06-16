import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var records: [PuzzleRecord]
    @Query private var dailies: [DailyResult]

    private var summary: StatsSummary {
        StatsEngine.summarize(records: records, dailies: dailies)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if summary.isEmpty {
                    EmptyStateView(
                        symbol: "chart.bar.xaxis",
                        title: "No solves yet",
                        message: "Solve a few puzzles and your progress, best times, and daily streak will appear here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            overviewGrid
                            sizeCard
                            timesCard
                            streakCard
                        }
                        .padding(18)
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }

    // MARK: Overview

    private var overviewGrid: some View {
        let s = summary
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            StatChip(caption: "Solved", value: "\(s.totalSolved)")
            StatChip(caption: "Complete", value: "\(s.completionPercent)%")
            StatChip(caption: "Best time", value: s.bestTimeLabel)
            StatChip(caption: "Total time", value: s.totalTimeLabel)
            StatChip(caption: "Streak", value: "\(s.currentStreak)")
            StatChip(caption: "Mistakes", value: "\(s.totalMistakes)")
        }
    }

    // MARK: Solved by size

    private var sizeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Solved by size", systemImage: "square.grid.2x2")
            Chart(summary.sizeBuckets) { bucket in
                BarMark(
                    x: .value("Size", bucket.sizeLabel),
                    y: .value("Solved", bucket.solved)
                )
                .foregroundStyle(Theme.accent)
                .cornerRadius(6)
                .annotation(position: .top) {
                    Text("\(bucket.solved)/\(bucket.total)")
                        .font(Theme.mono(10, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .frame(height: 180)
            .accessibilityLabel(sizeAccessibility)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private var sizeAccessibility: String {
        let parts = summary.sizeBuckets.map { "\($0.sizeLabel): \($0.solved) of \($0.total)" }
        return "Bar chart of puzzles solved by size. " + parts.joined(separator: ", ") + "."
    }

    // MARK: Best-time distribution

    private var timesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Best-time distribution", systemImage: "timer")
            if summary.timeBuckets.isEmpty {
                Text("Solve a puzzle to see your time bands.")
                    .font(Theme.rounded(13)).foregroundStyle(Theme.inkFaint)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart(summary.timeBuckets) { bucket in
                    BarMark(
                        x: .value("Band", bucket.label),
                        y: .value("Puzzles", bucket.count)
                    )
                    .foregroundStyle(Theme.accentDeep)
                    .cornerRadius(6)
                }
                .frame(height: 180)
                .accessibilityLabel(timeAccessibility)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private var timeAccessibility: String {
        let parts = summary.timeBuckets.sorted { $0.order < $1.order }.map { "\($0.label): \($0.count)" }
        return "Bar chart of best times by band. " + parts.joined(separator: ", ") + "."
    }

    // MARK: Streak / completion

    private var streakCard: some View {
        let s = summary
        let solved = s.totalSolved
        let remaining = max(0, s.totalPuzzles - solved)
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Library completion", systemImage: "chart.pie.fill")
            Chart {
                SectorMark(angle: .value("Solved", solved), innerRadius: .ratio(0.6))
                    .foregroundStyle(Theme.accent)
                SectorMark(angle: .value("Remaining", remaining), innerRadius: .ratio(0.6))
                    .foregroundStyle(Theme.hairline)
            }
            .frame(height: 170)
            .accessibilityLabel("Pie chart: \(solved) of \(s.totalPuzzles) puzzles solved, \(s.completionPercent) percent.")

            HStack {
                legendDot(color: Theme.accent, text: "Solved (\(solved))")
                Spacer()
                legendDot(color: Theme.hairline, text: "Remaining (\(remaining))")
            }
            HStack {
                Text("Best daily streak")
                    .font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                Spacer()
                Text("\(s.bestStreak) days")
                    .font(Theme.rounded(16, .bold)).foregroundStyle(Theme.accent)
            }
            .padding(.top, 2)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private func legendDot(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(text).font(Theme.rounded(12, .medium)).foregroundStyle(Theme.inkSoft)
        }
        .accessibilityElement(children: .combine)
    }
}
