import SwiftUI
import SwiftData
import Charts

/// Viewing stats via Swift Charts, computed in an async @MainActor function with a loading state.
struct StatsScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var titles: [Title]

    @State private var result: StatsResult?
    @State private var isLoading = false
    @State private var showPaywall = false

    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }

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
                        Button { showPaywall = true } label: {
                            Label("Pro", systemImage: "crown.fill")
                                .font(Theme.rounded(13, .semibold))
                        }
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(reason: .fullStats)
            }
        }
        .task(id: dataSignature) { await recompute() }
    }

    /// Recompute whenever the underlying data meaningfully changes.
    private var dataSignature: String {
        let count = titles.count
        let watched = titles.reduce(0) { $0 + $1.watchedEpisodes + ($1.status == .watched ? 1 : 0) }
        let entries = titles.reduce(0) { $0 + $1.entries.count }
        return "\(count)-\(watched)-\(entries)"
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Theme.accent)
                Text("Crunching your year in film…")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
            }
            .accessibilityLabel("Computing statistics")
        } else if let result, !result.isEmpty {
            ScrollView {
                VStack(spacing: 16) {
                    summaryGrid(result)
                    goalGauge(result)
                    filmsVsShows(result)
                    monthlyChart(result)
                    ratingsChart(result)
                    if isPro {
                        genreDonut(result)
                        decadeChart(result)
                    } else {
                        proTeaser
                    }
                }
                .padding(20)
            }
        } else {
            EmptyStateView(symbol: "chart.bar.xaxis",
                           title: "No stats yet",
                           message: "Mark a few titles as watched and your viewing patterns will appear here.")
        }
    }

    // MARK: Summary (free)

    private func summaryGrid(_ r: StatsResult) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatChip(caption: "Watched", value: "\(r.totalWatched)", systemImage: "checkmark.circle")
            StatChip(caption: "Hours", value: formatHours(r.totalHours), systemImage: "clock")
            StatChip(caption: "Avg rating",
                     value: r.averageRating > 0 ? String(format: "%.1f", r.averageRating) : "—",
                     systemImage: "star", tint: Theme.gold)
            StatChip(caption: "Day streak", value: "\(r.longestStreak)", systemImage: "flame", tint: Theme.warn)
        }
    }

    private func formatHours(_ hours: Double) -> String {
        if hours >= 100 { return "\(Int(hours))" }
        return String(format: "%.1f", hours)
    }

    // MARK: Goal gauge (free)

    private func goalGauge(_ r: StatsResult) -> some View {
        let goal = max(1, settings.yearlyGoal)
        let progress = min(1, Double(r.thisYearCount) / Double(goal))
        return chartCard(title: "\(currentYear) goal", symbol: "target") {
            HStack(spacing: 18) {
                GoalRing(progress: progress)
                    .frame(width: 78, height: 78)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(r.thisYearCount) of \(goal)")
                        .font(Theme.rounded(24, .bold))
                        .foregroundStyle(Theme.ink)
                        .monospacedDigit()
                    Text(r.thisYearCount >= goal ? "Goal reached!" : "\(goal - r.thisYearCount) to go")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(currentYear) goal: \(r.thisYearCount) of \(goal)")
        }
    }

    // MARK: Films vs Shows (free)

    private func filmsVsShows(_ r: StatsResult) -> some View {
        let data = [CountSlice(label: "Films", count: r.filmCount),
                    CountSlice(label: "Shows", count: r.showCount)]
        return chartCard(title: "Films vs shows", symbol: "rectangle.split.2x1") {
            if r.filmCount + r.showCount == 0 {
                emptyChartNote("No watched titles yet.")
            } else {
                Chart(data) { slice in
                    BarMark(x: .value("Count", slice.count),
                            y: .value("Kind", slice.label))
                    .foregroundStyle(slice.label == "Films" ? Theme.accent : Theme.accentDeep)
                    .cornerRadius(5)
                    .annotation(position: .trailing) {
                        Text("\(slice.count)")
                            .font(Theme.rounded(11, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: 96)
                .accessibilityLabel("Films \(r.filmCount), shows \(r.showCount)")
            }
        }
    }

    // MARK: Monthly chart (free)

    private func monthlyChart(_ r: StatsResult) -> some View {
        chartCard(title: "Watched per month (\(currentYear))", symbol: "calendar") {
            Chart(r.monthCounts) { m in
                BarMark(x: .value("Month", m.label),
                        y: .value("Count", m.count))
                .foregroundStyle(Theme.accent.gradient)
                .cornerRadius(3)
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 180)
            .accessibilityLabel("Watches per month bar chart")
        }
    }

    // MARK: Ratings histogram (free)

    private func ratingsChart(_ r: StatsResult) -> some View {
        chartCard(title: "Ratings distribution", symbol: "star.leadinghalf.filled") {
            if r.ratingHistogram.allSatisfy({ $0.count == 0 }) {
                emptyChartNote("Rate some titles to see this.")
            } else {
                Chart(r.ratingHistogram) { bin in
                    BarMark(x: .value("Stars", bin.label),
                            y: .value("Count", bin.count))
                    .foregroundStyle(Theme.gold.gradient)
                    .cornerRadius(3)
                }
                .frame(height: 180)
                .accessibilityLabel("Ratings histogram from half a star to five stars")
            }
        }
    }

    // MARK: Genre donut (Pro)

    private func genreDonut(_ r: StatsResult) -> some View {
        chartCard(title: "Top genres", symbol: "theatermasks") {
            let top = Array(r.genreCounts.prefix(7))
            if top.isEmpty {
                emptyChartNote("No genres tagged yet.")
            } else {
                Chart(top) { slice in
                    SectorMark(angle: .value("Count", slice.count),
                               innerRadius: .ratio(0.58),
                               angularInset: 1.5)
                    .foregroundStyle(by: .value("Genre", slice.label))
                    .cornerRadius(3)
                }
                .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
                .frame(height: 240)
                .accessibilityLabel("Top genres donut chart")
            }
        }
    }

    // MARK: Decade chart (Pro)

    private func decadeChart(_ r: StatsResult) -> some View {
        chartCard(title: "By decade", symbol: "clock.arrow.circlepath") {
            if r.decadeCounts.isEmpty {
                emptyChartNote("No watched titles yet.")
            } else {
                Chart(r.decadeCounts) { slice in
                    BarMark(x: .value("Decade", slice.label),
                            y: .value("Count", slice.count))
                    .foregroundStyle(Theme.accentDeep.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .accessibilityLabel("Watched titles by decade bar chart")
            }
        }
    }

    private var proTeaser: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 32))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Unlock your full stats")
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.ink)
            Text("The genre donut and by-decade history are part of Reel Pro. See the complete shape of your taste.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "See Reel Pro", systemImage: "crown.fill") {
                showPaywall = true
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .cardSurface()
    }

    private func emptyChartNote(_ text: String) -> some View {
        Text(text)
            .font(Theme.rounded(14))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, minHeight: 80)
    }

    private func chartCard<Content: View>(title: String, symbol: String,
                                          @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(Theme.rounded(17, .bold))
                .foregroundStyle(Theme.ink)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    // MARK: Async compute (loading state)

    @MainActor
    private func recompute() async {
        isLoading = true
        let snapshot = titles
        let year = currentYear
        // Brief delay so the loading state is perceptible on fast devices.
        try? await Task.sleep(nanoseconds: 350_000_000)
        result = StatsEngine.compute(titles: snapshot, year: year)
        isLoading = false
    }
}

#Preview {
    StatsScreen()
        .environmentObject(AppSettings())
        .modelContainer(PreviewContainer.shared)
}
