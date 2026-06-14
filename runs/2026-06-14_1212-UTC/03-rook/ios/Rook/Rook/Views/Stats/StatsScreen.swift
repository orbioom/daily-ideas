import SwiftUI
import SwiftData
import Charts

/// Stats — Swift Charts over games and puzzle results, computed async with a loading state.
struct StatsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var games: [GameRecord]
    @Query private var puzzles: [PuzzleResult]

    @State private var result: StatsResult?
    @State private var isLoading = false
    @State private var paywallReason: PaywallReason?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Stats")
            .toolbar {
                if !isPro {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { paywallReason = .stats } label: {
                            Label("Pro", systemImage: "crown.fill")
                                .font(Theme.rounded(13, .semibold))
                        }
                    }
                }
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
        .task(id: signature) { await recompute() }
    }

    private var signature: String {
        "\(games.count)-\(puzzles.count)"
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack(spacing: 14) {
                ProgressView().controlSize(.large).tint(Theme.accent)
                Text("Crunching your numbers…")
                    .font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
            }
            .accessibilityLabel("Computing statistics")
        } else if let result, !result.isEmpty {
            ScrollView {
                VStack(spacing: 16) {
                    headlineGrid(result)
                    resultsCard(result)
                    if isPro {
                        accuracyCard(result)
                        solvedOverTimeCard(result)
                        themeCard(result)
                    } else {
                        proTeaser
                    }
                }
                .padding(16)
            }
        } else {
            EmptyStateView(symbol: "chart.bar.xaxis",
                           title: "No stats yet",
                           message: "Play a game or solve a puzzle and your progress will appear here.")
        }
    }

    // MARK: Headline numbers

    private func headlineGrid(_ r: StatsResult) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard("Games", "\(r.gamesPlayed)", "checkerboard.rectangle")
            statCard("Win rate", percent(r.winRate), "trophy")
            statCard("Puzzles solved", "\(r.puzzlesSolved)", "puzzlepiece.extension")
            statCard("Current streak", "\(r.currentStreak)", "flame.fill")
        }
    }

    private func statCard(_ title: String, _ value: String, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(value)
                .font(Theme.rounded(26, .bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
            Text(title).font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: Games W/L/D (free)

    private func resultsCard(_ r: StatsResult) -> some View {
        SectionCard(title: "Game results", symbol: "trophy") {
            if r.gamesPlayed == 0 {
                Text("No finished games yet — play to the end on the Play tab.")
                    .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
            } else {
                Chart {
                    BarMark(x: .value("Result", "Wins"), y: .value("Count", r.wins))
                        .foregroundStyle(Theme.good)
                    BarMark(x: .value("Result", "Losses"), y: .value("Count", r.losses))
                        .foregroundStyle(Theme.bad)
                    BarMark(x: .value("Result", "Draws"), y: .value("Count", r.draws))
                        .foregroundStyle(Theme.inkSoft)
                }
                .frame(height: 180)
                .accessibilityLabel("Wins \(r.wins), losses \(r.losses), draws \(r.draws)")
            }
        }
    }

    // MARK: Pro charts

    private func accuracyCard(_ r: StatsResult) -> some View {
        SectionCard(title: "Puzzle accuracy", symbol: "target") {
            VStack(spacing: 12) {
                Chart {
                    BarMark(x: .value("Kind", "Solved"), y: .value("Count", r.puzzlesSolved))
                        .foregroundStyle(Theme.accent)
                    BarMark(x: .value("Kind", "Attempted"), y: .value("Count", r.puzzlesAttempted))
                        .foregroundStyle(Theme.accent.opacity(0.4))
                }
                .frame(height: 160)
                HStack {
                    Text("Accuracy").font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Text(percent(r.puzzleAccuracy))
                        .font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink).monospacedDigit()
                }
                HStack {
                    Text("Best streak").font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Text("\(r.bestStreak)")
                        .font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink).monospacedDigit()
                }
            }
        }
    }

    private func solvedOverTimeCard(_ r: StatsResult) -> some View {
        SectionCard(title: "Solved over time", symbol: "calendar") {
            Chart(r.solvedOverTime) { day in
                BarMark(x: .value("Day", day.date, unit: .day),
                        y: .value("Solved", day.solved))
                    .foregroundStyle(Theme.accent.gradient)
                    .cornerRadius(3)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                    AxisGridLine(); AxisTick()
                    AxisValueLabel(format: .dateTime.day().month(.narrow))
                }
            }
            .frame(height: 160)
            .accessibilityLabel("Puzzles solved per day over the last two weeks")
        }
    }

    private func themeCard(_ r: StatsResult) -> some View {
        SectionCard(title: "By theme", symbol: "square.grid.2x2") {
            if r.themeBars.isEmpty {
                Text("Solve puzzles across themes to compare your strengths.")
                    .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
            } else {
                Chart(r.themeBars) { stat in
                    BarMark(x: .value("Solved", stat.solved),
                            y: .value("Theme", stat.theme))
                        .foregroundStyle(Theme.accent)
                        .annotation(position: .trailing) {
                            Text("\(stat.solved)/\(stat.attempted)")
                                .font(Theme.rounded(11, .semibold))
                                .foregroundStyle(Theme.inkSoft)
                        }
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(r.themeBars.count) * 34 + 10)
                .accessibilityLabel("Solved puzzles by theme")
            }
        }
    }

    private var proTeaser: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 32)).foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Unlock full stats")
                .font(Theme.serif(20, .semibold)).foregroundStyle(Theme.ink)
            Text("Accuracy, your solving streak over time, and by-theme breakdowns are part of Rook Pro.")
                .font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "See Rook Pro", systemImage: "crown.fill") {
                paywallReason = .stats
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    private func percent(_ v: Double) -> String {
        "\(Int((v * 100).rounded()))%"
    }

    @MainActor
    private func recompute() async {
        isLoading = true
        let g = games
        let p = puzzles
        try? await Task.sleep(nanoseconds: 300_000_000)
        result = StatsEngine.compute(games: g, puzzles: p)
        isLoading = false
    }
}
