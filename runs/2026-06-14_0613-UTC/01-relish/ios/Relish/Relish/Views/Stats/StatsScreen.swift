import SwiftUI
import SwiftData
import Charts

/// Taste Stats — Swift Charts, computed in an async @MainActor function with a loading state.
struct StatsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var allRestaurants: [Restaurant]

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

    /// Recompute whenever the underlying data meaningfully changes.
    private var dataSignature: String {
        let count = allRestaurants.count
        let ranks = allRestaurants.reduce(0) { $0 + $1.rankIndex }
        return "\(count)-\(ranks)"
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
                        cuisineChart(result)
                        scoreHistogram(result)
                        cityChart(result)
                        topDishesCard(result)
                    } else {
                        proTeaser
                    }
                }
                .padding(20)
            }
        } else {
            EmptyStateView(symbol: "chart.bar.xaxis",
                           title: "No stats yet",
                           message: "Rank a few places and your taste map will appear here.")
        }
    }

    // MARK: Summary (free)

    private func summaryGrid(_ r: StatsResult) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard("Ranked", "\(r.totalRanked)", "list.number")
            statCard("Avg score", settings.formatScore(r.averageScore), "number")
            statCard("Want to try", "\(r.totalWishlist)", "bookmark")
            statCard("Total spent", settings.formatMoney(r.totalSpent), "creditcard")
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

    private func cuisineChart(_ r: StatsResult) -> some View {
        chartCard(title: "Cuisines you eat most", symbol: "fork.knife") {
            let top = Array(r.cuisineCounts.prefix(8))
            Chart(top) { item in
                BarMark(
                    x: .value("Count", item.count),
                    y: .value("Cuisine", item.label)
                )
                .foregroundStyle(item.cuisine?.hue ?? Theme.accent)
                .cornerRadius(5)
                .annotation(position: .trailing) {
                    Text("\(item.count)")
                        .font(Theme.rounded(11, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .chartXAxis(.hidden)
            .frame(height: CGFloat(top.count) * 34 + 10)
            .accessibilityLabel("Cuisine distribution bar chart")
        }
    }

    private func cityChart(_ r: StatsResult) -> some View {
        chartCard(title: "Cities", symbol: "building.2") {
            let top = Array(r.cityCounts.prefix(8))
            Chart(top) { item in
                BarMark(
                    x: .value("City", item.label),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(Theme.accent.gradient)
                .cornerRadius(5)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 200)
            .accessibilityLabel("City distribution bar chart")
        }
    }

    private func scoreHistogram(_ r: StatsResult) -> some View {
        chartCard(title: "Score distribution", symbol: "chart.bar") {
            Chart(r.scoreHistogram) { bin in
                BarMark(
                    x: .value("Score", bin.label),
                    y: .value("Count", bin.count)
                )
                .foregroundStyle(Theme.accent.gradient)
                .cornerRadius(4)
            }
            .frame(height: 180)
            .accessibilityLabel("Score histogram from 0 to 10")
        }
    }

    private func topDishesCard(_ r: StatsResult) -> some View {
        chartCard(title: "Top dishes", symbol: "star.fill") {
            if r.topDishes.isEmpty {
                Text("Log dishes on a restaurant to see them ranked here.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 10) {
                    ForEach(r.topDishes) { dish in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(dish.name)
                                    .font(Theme.rounded(15, .semibold))
                                    .foregroundStyle(Theme.ink)
                                Text(dish.restaurant)
                                    .font(Theme.rounded(12))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            Spacer()
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { i in
                                    Image(systemName: i <= dish.rating ? "star.fill" : "star")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.accent)
                                }
                            }
                            .accessibilityLabel("\(dish.rating) of 5 stars")
                        }
                    }
                }
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
                .font(Theme.serif(20, .semibold))
                .foregroundStyle(Theme.ink)
            Text("Cuisine and city breakdowns, your score histogram, and top dishes are part of Relish Pro.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "See Relish Pro", systemImage: "crown.fill") {
                paywallReason = .stats
            }
        }
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    private func chartCard<Content: View>(title: String, symbol: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(Theme.serif(18, .semibold))
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
        // Snapshot a stable scorebook, then compute off it.
        let book = ScoreBook(allRestaurants: allRestaurants)
        let snapshot = allRestaurants
        // Brief delay so the loading state is perceptible on fast devices.
        try? await Task.sleep(nanoseconds: 350_000_000)
        let computed = StatsEngine.compute(restaurants: snapshot) { book.score($0) }
        result = computed
        isLoading = false
    }
}
