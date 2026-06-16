import SwiftUI
import SwiftData
import Charts

/// Stats dashboard — Swift Charts computed off snapshots in an async @MainActor task.
/// Summary is free; the chart deck (forecast, maturity, retention, streak) is Pro.
struct StatsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query private var allCards: [Card]
    @Query private var allLogs: [ReviewLog]
    @Query private var allDecks: [Deck]

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
        .task(id: dataSignature) { await recompute() }
    }

    /// Recompute whenever the data meaningfully changes.
    private var dataSignature: String {
        let cards = allCards.count
        let logs = allLogs.count
        let intervals = allCards.reduce(0) { $0 + $1.intervalDays }
        return "\(cards)-\(logs)-\(intervals)"
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack(spacing: 14) {
                ProgressView().controlSize(.large).tint(Theme.accent)
                Text("Crunching your memory…")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
            }
            .accessibilityLabel("Computing statistics")
        } else if let result, !result.isEmpty {
            ScrollView {
                VStack(spacing: 16) {
                    summaryGrid(result)
                    if isPro {
                        activityChart(result)
                        forecastChart(result)
                        maturityChart(result)
                    } else {
                        proTeaser
                    }
                }
                .padding(20)
            }
        } else {
            EmptyStateView(symbol: "chart.bar.xaxis",
                           title: "No stats yet",
                           message: "Study a few cards and your activity, forecast, and memory map will appear here.")
        }
    }

    // MARK: Summary (free)

    private func summaryGrid(_ r: StatsResult) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(caption: "Due today", value: "\(r.dueToday)", systemImage: "tray.full", tint: Theme.warn)
            StatCard(caption: "Total cards", value: "\(r.totalCards)", systemImage: "rectangle.stack")
            StatCard(caption: "Retention", value: "\(r.retentionPercent)%", systemImage: "target", tint: Theme.good)
            StatCard(caption: "Study streak", value: "\(r.streakDays)\(r.streakDays == 1 ? " day" : " days")", systemImage: "flame.fill", tint: Theme.bad)
        }
    }

    // MARK: Activity (Pro)

    private func activityChart(_ r: StatsResult) -> some View {
        chartCard(title: "Reviews — last 30 days", symbol: "calendar") {
            Chart(r.reviewsLast30) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Reviews", day.count)
                )
                .foregroundStyle(Theme.accent.gradient)
                .cornerRadius(2)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 180)
            .accessibilityLabel("Daily reviews bar chart for the last 30 days")
        }
    }

    // MARK: Forecast (Pro)

    private func forecastChart(_ r: StatsResult) -> some View {
        chartCard(title: "Due forecast — next 14 days", symbol: "calendar.badge.clock") {
            Chart(r.forecastNext14) { day in
                BarMark(
                    x: .value("Day", day.label),
                    y: .value("Cards", day.count)
                )
                .foregroundStyle(Theme.warn.gradient)
                .cornerRadius(3)
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label).font(.system(size: 9))
                        }
                    }
                }
            }
            .frame(height: 180)
            .accessibilityLabel("Forecast of cards becoming due over the next 14 days")
        }
    }

    // MARK: Maturity donut (Pro)

    private func maturityChart(_ r: StatsResult) -> some View {
        chartCard(title: "Card maturity", symbol: "circle.grid.cross") {
            let slices = r.maturityMix.filter { $0.count > 0 }
            if slices.isEmpty {
                Text("Study cards to grow them from New to Mature.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(spacing: 18) {
                    Chart(slices) { slice in
                        SectorMark(
                            angle: .value("Count", slice.count),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .foregroundStyle(slice.maturity.color)
                        .cornerRadius(3)
                    }
                    .frame(width: 130, height: 130)
                    .accessibilityLabel("Card maturity donut chart")

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(r.maturityMix) { slice in
                            HStack(spacing: 8) {
                                Circle().fill(slice.maturity.color).frame(width: 10, height: 10)
                                Text(slice.maturity.rawValue)
                                    .font(Theme.rounded(13, .medium))
                                    .foregroundStyle(Theme.ink)
                                Spacer()
                                Text("\(slice.count)")
                                    .font(Theme.rounded(13, .bold))
                                    .monospacedDigit()
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(slice.maturity.rawValue): \(slice.count)")
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
            Text("Unlock the full dashboard")
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.ink)
            Text("Your 30-day activity, due forecast, and card-maturity map are part of Recall Pro.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "See Recall Pro", systemImage: "crown.fill") {
                paywallReason = .stats
            }
        }
        .padding(22)
        .cardSurface()
    }

    private func chartCard<Content: View>(title: String, symbol: String, @ViewBuilder content: () -> Content) -> some View {
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
        let cards = allCards
        let logs = allLogs
        let deckCount = allDecks.filter { !$0.isArchived }.count
        // Brief delay so the loading state is perceptible.
        try? await Task.sleep(nanoseconds: 300_000_000)
        result = StatsEngine.compute(cards: cards, logs: logs, deckCount: deckCount)
        isLoading = false
    }
}

#Preview {
    StatsScreen()
        .environmentObject(AppSettings())
        .modelContainer(PreviewContainer.shared)
}
