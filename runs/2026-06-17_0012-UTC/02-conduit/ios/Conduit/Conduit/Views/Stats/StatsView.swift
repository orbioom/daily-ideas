import SwiftUI
import SwiftData
import Charts

/// Player statistics: totals, streaks, per-pack completion, and (Pro) charts.
struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @AppStorage("isPro") private var isPro: Bool = false
    @Query private var progress: [PuzzleProgress]
    @Query(sort: \DailyResult.date, order: .reverse) private var dailyResults: [DailyResult]

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if !hasAnyActivity {
                        emptyState
                    } else {
                        totalsCard
                        streakCard
                        packCompletionCard
                        if isPro {
                            solvedTrendCard
                            sizeCompletionCard
                        } else {
                            proChartsTeaser
                        }
                    }
                }
                .padding(16)
            }
            .background(ConduitTheme.appBackground(scheme).ignoresSafeArea())
            .navigationTitle("Stats")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 56))
                .foregroundStyle(ConduitTheme.accent.opacity(0.7))
                .accessibilityHidden(true)
            Text("No stats yet").font(.title3.weight(.semibold))
                .foregroundStyle(ConduitTheme.primaryText(scheme))
            Text("Solve your first puzzle and your progress will appear here.")
                .font(.subheadline)
                .foregroundStyle(ConduitTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    // MARK: - Totals

    private var totalsCard: some View {
        ConduitCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Overview").font(.headline)
                    .foregroundStyle(ConduitTheme.primaryText(scheme))
                HStack(spacing: 12) {
                    bigStat("\(solvedCount)", "Solved", "checkmark.circle.fill")
                    bigStat("\(perfectCount)", "Perfect", "star.fill")
                }
                HStack(spacing: 12) {
                    bigStat(DailyPuzzle.formatTime(totalSeconds), "Total time", "clock.fill")
                    bigStat("\(completionPercent)%", "Complete", "chart.pie.fill")
                }
            }
        }
    }

    private func bigStat(_ value: String, _ label: String, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(ConduitTheme.accent).frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(ConduitTheme.primaryText(scheme))
                Text(label).font(.caption).foregroundStyle(ConduitTheme.secondaryText(scheme))
            }
            Spacer()
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(ConduitTheme.subtleSurface(scheme)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    // MARK: - Streak

    private var streakCard: some View {
        ConduitCard {
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Image(systemName: "flame.fill").foregroundStyle(ConduitTheme.accent)
                    Text("\(currentStreak)").font(.title2.weight(.bold))
                        .foregroundStyle(ConduitTheme.primaryText(scheme))
                    Text("current daily streak").font(.caption2)
                        .foregroundStyle(ConduitTheme.secondaryText(scheme))
                }
                .frame(maxWidth: .infinity)
                Divider().frame(height: 50)
                VStack(spacing: 4) {
                    Image(systemName: "trophy.fill").foregroundStyle(ConduitTheme.accent)
                    Text("\(bestStreak)").font(.title2.weight(.bold))
                        .foregroundStyle(ConduitTheme.primaryText(scheme))
                    Text("best daily streak").font(.caption2)
                        .foregroundStyle(ConduitTheme.secondaryText(scheme))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Per-pack completion

    private var packCompletionCard: some View {
        ConduitCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Pack completion").font(.headline)
                    .foregroundStyle(ConduitTheme.primaryText(scheme))
                ForEach(PackID.allCases) { pack in
                    let total = PuzzleBank.puzzles(in: pack).count
                    let solved = solvedCount(in: pack)
                    let frac = total > 0 ? Double(solved) / Double(total) : 0
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(pack.title).font(.subheadline)
                                .foregroundStyle(ConduitTheme.primaryText(scheme))
                            Spacer()
                            Text("\(solved)/\(total)").font(.caption.monospacedDigit())
                                .foregroundStyle(ConduitTheme.secondaryText(scheme))
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(ConduitTheme.subtleSurface(scheme))
                                Capsule().fill(ConduitTheme.accent)
                                    .frame(width: max(0, min(1, frac)) * geo.size.width)
                            }
                        }
                        .frame(height: 8)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(pack.title): \(solved) of \(total) solved")
                }
            }
        }
    }

    // MARK: - Pro charts

    private var solvedTrendCard: some View {
        ConduitCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Daily solves · last 30 days").font(.headline)
                    .foregroundStyle(ConduitTheme.primaryText(scheme))
                let data = solvedPerDay()
                Chart(data, id: \.day) { point in
                    BarMark(
                        x: .value("Day", point.day),
                        y: .value("Solved", point.count)
                    )
                    .foregroundStyle(ConduitTheme.accent)
                    .cornerRadius(2)
                }
                .frame(height: 160)
                .chartYAxis { AxisMarks(values: .automatic(desiredCount: 3)) }
                .accessibilityLabel("Bar chart of daily puzzles solved over the last 30 days")
            }
        }
    }

    private var sizeCompletionCard: some View {
        ConduitCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Solved by board size").font(.headline)
                    .foregroundStyle(ConduitTheme.primaryText(scheme))
                let data = solvedBySize()
                Chart(data, id: \.size) { point in
                    BarMark(
                        x: .value("Size", "\(point.size)×\(point.size)"),
                        y: .value("Solved", point.count)
                    )
                    .foregroundStyle(ConduitTheme.accent.gradient)
                    .cornerRadius(3)
                }
                .frame(height: 160)
                .accessibilityLabel("Bar chart of puzzles solved by board size")
            }
        }
    }

    private var proChartsTeaser: some View {
        Button {
            showPaywall = true
        } label: {
            ConduitCard {
                HStack(spacing: 14) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2).foregroundStyle(ConduitTheme.accent)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Detailed charts").font(.headline)
                            .foregroundStyle(ConduitTheme.primaryText(scheme))
                        Text("Unlock trend and board-size charts with Conduit Pro.")
                            .font(.caption)
                            .foregroundStyle(ConduitTheme.secondaryText(scheme))
                    }
                    Spacer()
                    Image(systemName: "lock.fill").foregroundStyle(ConduitTheme.secondaryText(scheme))
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Derived

    private var hasAnyActivity: Bool {
        solvedCount > 0 || !dailyResults.isEmpty
    }
    private var solvedCount: Int { progress.filter { $0.solved }.count }
    private var perfectCount: Int { progress.filter { $0.perfect }.count }
    private var totalSeconds: Int { progress.reduce(0) { $0 + max(0, $1.bestSeconds) } }
    private var completionPercent: Int {
        let total = PuzzleBank.all.count
        guard total > 0 else { return 0 }
        return Int((Double(solvedCount) / Double(total) * 100).rounded())
    }
    private func solvedCount(in pack: PackID) -> Int {
        let ids = Set(PuzzleBank.puzzles(in: pack).map { $0.id })
        return progress.filter { $0.solved && ids.contains($0.puzzleId) }.count
    }

    private var solvedKeys: [String] { dailyResults.filter { $0.solved }.map { $0.dayKey } }
    private var currentStreak: Int { Streak.current(solvedKeys: solvedKeys) }
    private var bestStreak: Int { Streak.best(solvedKeys: solvedKeys) }

    private struct DayCount { let day: Date; let count: Int }
    private func solvedPerDay() -> [DayCount] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        // Count solves per day across both daily results and level progress lastPlayed.
        var counts: [Date: Int] = [:]
        for result in dailyResults where result.solved {
            let d = cal.startOfDay(for: result.date)
            counts[d, default: 0] += 1
        }
        let windowStart = cal.date(byAdding: .day, value: -30, to: today) ?? today
        for row in progress where row.solved {
            let d = cal.startOfDay(for: row.lastPlayed)
            if d >= windowStart {
                counts[d, default: 0] += 1
            }
        }
        var out: [DayCount] = []
        for offset in stride(from: 29, through: 0, by: -1) {
            if let d = cal.date(byAdding: .day, value: -offset, to: today) {
                out.append(DayCount(day: d, count: counts[d] ?? 0))
            }
        }
        return out
    }

    private struct SizeCount { let size: Int; let count: Int }
    private func solvedBySize() -> [SizeCount] {
        var counts: [Int: Int] = [:]
        for row in progress where row.solved {
            counts[row.size, default: 0] += 1
        }
        return [5, 6, 7, 8, 9].map { SizeCount(size: $0, count: counts[$0] ?? 0) }
    }
}
