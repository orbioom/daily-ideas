import SwiftUI
import SwiftData
import Charts

/// Taste Stats — Swift Charts computed in an async @MainActor task with a loading state.
struct StatsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var allTitles: [Title]

    @State private var result: StatsResult?
    @State private var isLoading = false
    @State private var paywallReason: PaywallReason?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Taste Stats")
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
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
        }
        .task(id: dataSignature) { await recompute() }
    }

    private var dataSignature: String {
        let count = allTitles.count
        let prog = allTitles.reduce(0) { $0 + $1.progress + $1.score }
        let completed = allTitles.filter { $0.status == .completed }.count
        return "\(count)-\(prog)-\(completed)"
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Theme.accent)
                Text("Crunching your taste…")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
            }
            .accessibilityLabel("Computing statistics")
        } else if let result, !result.isEmpty {
            ScrollView {
                VStack(spacing: 16) {
                    summaryGrid(result)
                    if isPro {
                        statusDonut(result)
                        scoreHistogram(result)
                        topGenres(result)
                        completedPerMonth(result)
                    } else {
                        proTeaser
                    }
                }
                .padding(20)
            }
        } else {
            EmptyStateView(symbol: "chart.pie",
                           title: "No stats yet",
                           message: "Track a few titles and your taste map will appear here.")
        }
    }

    // MARK: Summary (free)

    private func summaryGrid(_ r: StatsResult) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard("Titles", "\(r.totalTitles)", "books.vertical.fill")
            statCard("Episodes", "\(r.episodesWatched)", "play.tv")
            statCard("Chapters", "\(r.chaptersRead)", "book")
            if settings.showTimeSpent {
                statCard("Time spent", settings.formatMinutes(r.minutesSpent), "clock")
            } else {
                statCard("Completed", "\(r.completedCount)", "checkmark.seal")
            }
            statCard("Mean score", r.ratedCount == 0 ? "—" : String(format: "%.1f", r.meanScore), "star.fill")
            statCard("Completion", "\(Int((r.completionRate * 100).rounded()))%", "percent")
        }
    }

    private func statCard(_ title: String, _ value: String, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(value)
                .font(Theme.display(24, .bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: Pro charts

    private func statusDonut(_ r: StatsResult) -> some View {
        chartCard(title: "Status breakdown", symbol: "chart.pie") {
            if r.statusSlices.isEmpty {
                emptyChartNote("No statuses to show yet.")
            } else {
                HStack(alignment: .center, spacing: 18) {
                    Chart(r.statusSlices) { slice in
                        SectorMark(
                            angle: .value("Count", slice.count),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .cornerRadius(4)
                        .foregroundStyle(slice.status.color)
                    }
                    .frame(width: 150, height: 150)
                    .accessibilityLabel("Status donut chart")

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(r.statusSlices) { slice in
                            HStack(spacing: 8) {
                                Circle().fill(slice.status.color).frame(width: 10, height: 10)
                                Text(slice.label)
                                    .font(Theme.rounded(13))
                                    .foregroundStyle(Theme.ink)
                                Spacer(minLength: 4)
                                Text("\(slice.count)")
                                    .font(Theme.rounded(13, .semibold))
                                    .foregroundStyle(Theme.inkSoft)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
        }
    }

    private func scoreHistogram(_ r: StatsResult) -> some View {
        chartCard(title: "Score distribution", symbol: "chart.bar") {
            if r.scoreHistogram.allSatisfy({ $0.count == 0 }) {
                emptyChartNote("Rate some titles to fill this in.")
            } else {
                Chart(r.scoreHistogram) { bin in
                    BarMark(
                        x: .value("Score", bin.label),
                        y: .value("Count", bin.count)
                    )
                    .foregroundStyle(Theme.accent.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .accessibilityLabel("Score histogram from 1 to 10")
            }
        }
    }

    private func topGenres(_ r: StatsResult) -> some View {
        chartCard(title: "Top genres", symbol: "tag") {
            let top = Array(r.topGenres.prefix(8))
            if top.isEmpty {
                emptyChartNote("Add genres to your titles to see this.")
            } else {
                Chart(top) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Genre", item.label)
                    )
                    .foregroundStyle(Theme.violet.gradient)
                    .cornerRadius(5)
                    .annotation(position: .trailing) {
                        Text("\(item.count)")
                            .font(Theme.rounded(11, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(top.count) * 34 + 10)
                .accessibilityLabel("Top genres bar chart")
            }
        }
    }

    private func completedPerMonth(_ r: StatsResult) -> some View {
        chartCard(title: "Completed per month", symbol: "calendar") {
            if r.completedPerMonth.allSatisfy({ $0.count == 0 }) {
                emptyChartNote("Finish a title and it'll chart here.")
            } else {
                Chart(r.completedPerMonth) { m in
                    BarMark(
                        x: .value("Month", m.label),
                        y: .value("Completed", m.count)
                    )
                    .foregroundStyle(Theme.cyan.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .accessibilityLabel("Titles completed per month over the last year")
            }
        }
    }

    private var proTeaser: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 34))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Unlock full Taste Stats")
                .font(Theme.display(20, .bold))
                .foregroundStyle(Theme.ink)
            Text("Your status donut, score histogram, top genres, and completions over time are part of Senpai Pro.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "See Senpai Pro", systemImage: "crown.fill") {
                paywallReason = .stats
            }
        }
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    private func emptyChartNote(_ text: String) -> some View {
        Text(text)
            .font(Theme.rounded(14))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chartCard<Content: View>(title: String, symbol: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(Theme.display(18, .semibold))
                .foregroundStyle(Theme.ink)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    // MARK: Async compute (loading state)

    @MainActor
    private func recompute() async {
        isLoading = true
        let snapshot = allTitles
        try? await Task.sleep(nanoseconds: 300_000_000)
        result = StatsEngine.compute(titles: snapshot)
        isLoading = false
    }
}
