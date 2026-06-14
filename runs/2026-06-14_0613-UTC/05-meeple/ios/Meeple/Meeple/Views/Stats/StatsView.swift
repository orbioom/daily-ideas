import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var games: [BoardGame]
    @Query private var roster: [Player]

    @State private var snapshot: StatsSnapshot = .empty
    @State private var isLoading = true
    @State private var paywall: PaywallReason?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if isLoading {
                    loadingView
                } else if snapshot.totalPlays == 0 {
                    EmptyStateView(symbol: "chart.bar",
                                   title: "No stats yet",
                                   message: "Log a few plays and your stats will come alive here.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            totalsCard
                            mostPlayedCard
                            monthlyCard
                            if isPro {
                                hIndexCard
                                winRateCard
                            } else {
                                proStatsLock
                            }
                            weightCard
                            statusCard
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Stats")
            .sheet(item: $paywall) { r in PaywallView(reason: r) }
            .task(id: games.count) { await recompute() }
            .refreshable { await recompute() }
        }
    }

    @MainActor private func recompute() async {
        isLoading = true
        // Snapshot the inputs, then compute off the main hop to keep UI responsive.
        let snap = StatsEngine.compute(games: games, roster: roster)
        // Tiny yield so the loading state is visible on first appear.
        try? await Task.sleep(nanoseconds: 250_000_000)
        snapshot = snap
        isLoading = false
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView().controlSize(.large)
            Text("Crunching your plays…")
                .font(Theme.rounded(15)).foregroundStyle(Theme.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Computing statistics")
    }

    // MARK: Cards

    private var totalsCard: some View {
        CardSection("Totals") {
            let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: cols, spacing: 14) {
                totalTile("\(snapshot.totalPlays)", "Plays", "die.face.5.fill")
                totalTile("\(snapshot.uniqueGamesPlayed)", "Games played", "square.grid.2x2.fill")
                totalTile("\(snapshot.newToMeCount)", "New to me", "sparkles")
                totalTile(String(format: "%.0fh", snapshot.totalHours), "Hours", "clock.fill")
                totalTile(String(format: "%.1f", snapshot.averageWeightPlayed), "Avg weight", "scalemass.fill")
                totalTile("\(snapshot.ownedCount)", "Owned", "checkmark.seal.fill")
            }
        }
    }

    private func totalTile(_ value: String, _ label: String, _ symbol: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol).font(.system(size: 16)).foregroundStyle(Theme.accent)
            Text(value).font(Theme.rounded(20, .bold)).foregroundStyle(Theme.textPrimary)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(Theme.rounded(11)).foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var mostPlayedCard: some View {
        CardSection("Most played") {
            if snapshot.mostPlayed.isEmpty {
                Text("No plays yet.").font(Theme.rounded(14)).foregroundStyle(Theme.textSecondary)
            } else {
                Chart(snapshot.mostPlayed) { entry in
                    BarMark(
                        x: .value("Plays", entry.count),
                        y: .value("Game", entry.title)
                    )
                    .foregroundStyle(Theme.accent.gradient)
                    .annotation(position: .trailing) {
                        Text("\(entry.count)").font(Theme.rounded(11, .bold)).foregroundStyle(Theme.textSecondary)
                    }
                    .accessibilityLabel(entry.title)
                    .accessibilityValue("\(entry.count) plays")
                }
                .chartXAxis { AxisMarks() }
                .frame(height: CGFloat(snapshot.mostPlayed.count) * 34 + 20)
            }
        }
    }

    private var monthlyCard: some View {
        CardSection("Plays per month") {
            Chart(snapshot.monthly) { m in
                BarMark(
                    x: .value("Month", m.label),
                    y: .value("Plays", m.count)
                )
                .foregroundStyle(Theme.accentDeep.gradient)
                .accessibilityLabel(m.label)
                .accessibilityValue("\(m.count) plays")
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) {
                    AxisValueLabel().font(Theme.rounded(9))
                }
            }
            .frame(height: 180)
        }
    }

    private var hIndexCard: some View {
        CardSection("Your gaming H-index") {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(Theme.accent.opacity(0.16)).frame(width: 72, height: 72)
                    Text("\(snapshot.hIndex)").font(Theme.rounded(30, .bold)).foregroundStyle(Theme.accent)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("H-index of \(snapshot.hIndex)")
                        .font(Theme.rounded(16, .bold)).foregroundStyle(Theme.textPrimary)
                    Text("You have \(snapshot.hIndex) games each played at least \(snapshot.hIndex) times. A favourite metric of dedicated players.")
                        .font(Theme.rounded(13)).foregroundStyle(Theme.textSecondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Gaming H-index is \(snapshot.hIndex). \(snapshot.hIndex) games each played at least \(snapshot.hIndex) times.")
        }
    }

    private var winRateCard: some View {
        CardSection("Win rate by player") {
            if snapshot.playerWinRates.isEmpty {
                Text("Log plays with scores to see win rates.")
                    .font(Theme.rounded(14)).foregroundStyle(Theme.textSecondary)
            } else {
                Chart(snapshot.playerWinRates) { p in
                    BarMark(
                        x: .value("Win rate", p.rate),
                        y: .value("Player", p.name)
                    )
                    .foregroundStyle(Theme.playerColor(hue: p.colorHue).gradient)
                    .annotation(position: .trailing) {
                        Text(p.ratePercentText).font(Theme.rounded(11, .bold)).foregroundStyle(Theme.textSecondary)
                    }
                    .accessibilityLabel(p.name)
                    .accessibilityValue("\(p.ratePercentText) win rate, \(p.wins) wins of \(p.playsWithResults)")
                }
                .chartXScale(domain: 0...1)
                .chartXAxis {
                    AxisMarks(values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
                        AxisValueLabel {
                            if let d = value.as(Double.self) {
                                Text("\(Int(d * 100))%").font(Theme.rounded(9))
                            }
                        }
                    }
                }
                .frame(height: CGFloat(snapshot.playerWinRates.count) * 34 + 20)
            }
        }
    }

    private var weightCard: some View {
        CardSection("Collection weight spread") {
            Chart(snapshot.weightDistribution) { b in
                BarMark(x: .value("Range", b.label), y: .value("Games", b.count))
                    .foregroundStyle(Theme.accent.gradient)
                    .annotation(position: .top) {
                        if b.count > 0 {
                            Text("\(b.count)").font(Theme.rounded(10, .bold)).foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .accessibilityLabel("Weight \(b.label)")
                    .accessibilityValue("\(b.count) games")
            }
            .frame(height: 150)
        }
    }

    private var statusCard: some View {
        CardSection("Collection by status") {
            VStack(spacing: 8) {
                ForEach(snapshot.statusCounts) { sc in
                    HStack {
                        Image(systemName: sc.status.symbol).foregroundStyle(sc.status.color).frame(width: 22)
                        Text(sc.status.label).font(Theme.rounded(14)).foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text("\(sc.count)").font(Theme.rounded(14, .bold)).foregroundStyle(Theme.textSecondary).monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(sc.status.label): \(sc.count) games")
                }
            }
        }
    }

    private var proStatsLock: some View {
        Button { paywall = .stats } label: {
            CardSection {
                HStack(spacing: 14) {
                    Image(systemName: "lock.fill").font(.system(size: 24)).foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Unlock the full stats lab").font(Theme.rounded(16, .bold)).foregroundStyle(Theme.textPrimary)
                        Text("Win rates, per-player analytics and your H-index are part of Meeple Pro.")
                            .font(Theme.rounded(13)).foregroundStyle(Theme.textSecondary).multilineTextAlignment(.leading)
                    }
                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
    }
}
