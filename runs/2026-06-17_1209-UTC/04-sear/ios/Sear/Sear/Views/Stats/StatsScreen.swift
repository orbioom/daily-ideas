import SwiftUI
import SwiftData
import Charts

/// Cook statistics with Swift Charts. Computed in an async @MainActor function
/// with a perceptible loading state.
struct StatsScreen: View {
    @Environment(AppSettings.self) private var settings
    @Query private var cooks: [Cook]

    @State private var result: StatsResult?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Cook Stats")
        }
        .task(id: dataSignature) { await recompute() }
    }

    /// Recompute when the underlying data changes meaningfully.
    private var dataSignature: String {
        let count = cooks.count
        let rated = cooks.reduce(0) { $0 + ($1.clampedRating ?? 0) }
        return "\(count)-\(rated)"
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack(spacing: 14) {
                ProgressView().controlSize(.large).tint(Theme.accent)
                Text("Tallying your cooks…")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
            }
            .accessibilityLabel("Computing statistics")
        } else if let result, !result.isEmpty {
            ScrollView {
                VStack(spacing: 16) {
                    summaryGrid(result)
                    proteinChart(result)
                    methodChart(result)
                    ratingsChart(result)
                    woodsChart(result)
                }
                .padding(16)
            }
        } else {
            EmptyStateView(symbol: "chart.bar.xaxis",
                           title: "No stats yet",
                           message: "Finish a cook or two and your grilling habits will show up here.")
        }
    }

    // MARK: Summary

    private func summaryGrid(_ r: StatsResult) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard("Cooks logged", "\(r.totalCooks)", "flame.fill")
            statCard("Finished", "\(r.doneCooks)", "checkmark.seal.fill")
            statCard("Avg rating", r.averageRating > 0 ? String(format: "%.1f", r.averageRating) : "—", "star.fill")
            statCard("Proteins", "\(r.byProtein.count)", "fork.knife")
        }
    }

    private func statCard(_ title: String, _ value: String, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(value)
                .font(Theme.numeral(26, .bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
            Text(title)
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .searCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: Charts

    private func proteinChart(_ r: StatsResult) -> some View {
        chartCard(title: "Cooks by protein", symbol: "fork.knife") {
            Chart(r.byProtein) { item in
                BarMark(
                    x: .value("Count", item.count),
                    y: .value("Protein", item.label)
                )
                .foregroundStyle(color(for: item.hue))
                .cornerRadius(5)
                .annotation(position: .trailing) {
                    Text("\(item.count)")
                        .font(Theme.rounded(11, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .chartXAxis(.hidden)
            .frame(height: CGFloat(max(r.byProtein.count, 1)) * 34 + 10)
            .accessibilityLabel("Bar chart of cooks by protein")
        }
    }

    private func methodChart(_ r: StatsResult) -> some View {
        chartCard(title: "By method", symbol: "flame") {
            Chart(r.byMethod) { item in
                BarMark(
                    x: .value("Method", item.label),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(color(for: item.hue))
                .cornerRadius(5)
            }
            .frame(height: 200)
            .accessibilityLabel("Bar chart of cooks by method")
        }
    }

    private func ratingsChart(_ r: StatsResult) -> some View {
        chartCard(title: "Ratings over time", symbol: "star") {
            if r.ratingsOverTime.count < 2 {
                Text("Rate a couple more cooks to see your trend.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Chart(r.ratingsOverTime) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Rating", point.rating)
                    )
                    .foregroundStyle(Theme.accent)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Rating", point.rating)
                    )
                    .foregroundStyle(Theme.accent)
                }
                .chartYScale(domain: 0...5)
                .frame(height: 200)
                .accessibilityLabel("Line chart of ratings over time")
            }
        }
    }

    private func woodsChart(_ r: StatsResult) -> some View {
        chartCard(title: "Favorite woods", symbol: "leaf") {
            if r.favoriteWoods.isEmpty {
                Text("Assign woods to your cooks to see your favorites.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Chart(r.favoriteWoods) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.58),
                        angularInset: 1.5
                    )
                    .cornerRadius(4)
                    .foregroundStyle(by: .value("Wood", item.label))
                }
                .chartLegend(position: .bottom, spacing: 8)
                .frame(height: 230)
                .accessibilityLabel("Donut chart of favorite woods")
            }
        }
    }

    private func chartCard<Content: View>(title: String, symbol: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(Theme.ink)
            content()
        }
        .searCard()
    }

    private func color(for token: ColorToken) -> Color {
        switch token {
        case .protein(let p): return p.hue
        case .method(let m): return m.hue
        case .accent: return Theme.accent
        case .ember: return Theme.ember
        }
    }

    // MARK: Async compute

    @MainActor
    private func recompute() async {
        isLoading = true
        let snapshot = cooks
        try? await Task.sleep(nanoseconds: 300_000_000)
        result = StatsEngine.compute(cooks: snapshot)
        isLoading = false
    }
}
