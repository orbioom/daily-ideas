import SwiftUI
import SwiftData
import Charts

/// Scent Stats — Swift Charts computed off the main actor with a loading state.
/// Headline numbers are free; the full charts are gated behind Pro.
struct StatsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var allFragrances: [Fragrance]

    @State private var result: StatsResult?
    @State private var isLoading = false
    @State private var paywallReason: PaywallReason?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Scent Stats")
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
        let count = allFragrances.count
        let wears = allFragrances.reduce(0) { $0 + $1.wears.count }
        let placements = allFragrances.reduce(0) { $0 + $1.placements.count }
        return "\(count)-\(wears)-\(placements)"
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack(spacing: 14) {
                ProgressView().controlSize(.large).tint(Theme.accent)
                Text("Distilling your stats…")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
            }
            .accessibilityLabel("Computing statistics")
        } else if let result, !result.isEmpty {
            ScrollView {
                VStack(spacing: 16) {
                    summaryGrid(result)
                    if isPro {
                        familyDonut(result)
                        seasonChart(result)
                        occasionChart(result)
                        houseChart(result)
                        wearsOverTimeChart(result)
                        costPerWearCard(result)
                        neglectedCard
                    } else {
                        proTeaser
                    }
                }
                .padding(20)
            }
        } else {
            EmptyStateView(symbol: "chart.pie",
                           title: "No stats yet",
                           message: "Add a few fragrances and log some wears — your taste map appears here.")
        }
    }

    // MARK: Summary (free)

    private func summaryGrid(_ r: StatsResult) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard("Bottles", "\(r.collectionCount)", "drop.fill")
            statCard("Collection value", settings.formatMoney(r.totalValue), "banknote")
            statCard("Wears this month", "\(r.wearsThisMonth)", "calendar")
            statCard("Total wears", "\(r.totalWears)", "flame")
        }
    }

    private func statCard(_ title: String, _ value: String, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(value)
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
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

    private func familyDonut(_ r: StatsResult) -> some View {
        chartCard(title: "Note families", symbol: "chart.pie") {
            if r.familySlices.isEmpty {
                emptyChartNote("Add note pyramids to see your family spread.")
            } else {
                HStack(alignment: .center, spacing: 16) {
                    Chart(r.familySlices) { slice in
                        SectorMark(
                            angle: .value("Count", slice.count),
                            innerRadius: .ratio(0.58),
                            angularInset: 1.5
                        )
                        .foregroundStyle(slice.family.hue)
                        .cornerRadius(3)
                    }
                    .frame(width: 150, height: 150)
                    .accessibilityLabel("Note family donut chart")

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(r.familySlices.prefix(6)) { slice in
                            HStack(spacing: 6) {
                                Circle().fill(slice.family.hue).frame(width: 9, height: 9)
                                Text(slice.family.rawValue)
                                    .font(Theme.rounded(12))
                                    .foregroundStyle(Theme.ink)
                                Spacer()
                                Text("\(slice.count)")
                                    .font(Theme.rounded(12, .semibold))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                        }
                    }
                }
            }
        }
    }

    private func seasonChart(_ r: StatsResult) -> some View {
        chartCard(title: "By season", symbol: "sun.max") {
            Chart(r.seasonCounts) { item in
                BarMark(
                    x: .value("Season", item.season.rawValue),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(item.season.hue)
                .cornerRadius(5)
            }
            .frame(height: 180)
            .accessibilityLabel("Season distribution bar chart")
        }
    }

    private func occasionChart(_ r: StatsResult) -> some View {
        chartCard(title: "By occasion", symbol: "calendar.badge.clock") {
            Chart(r.occasionCounts) { item in
                BarMark(
                    x: .value("Count", item.count),
                    y: .value("Occasion", item.occasion.rawValue)
                )
                .foregroundStyle(Theme.accent.gradient)
                .cornerRadius(5)
                .annotation(position: .trailing) {
                    Text("\(item.count)")
                        .font(Theme.rounded(11, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .chartXAxis(.hidden)
            .frame(height: CGFloat(r.occasionCounts.count) * 30 + 10)
            .accessibilityLabel("Occasion distribution bar chart")
        }
    }

    private func houseChart(_ r: StatsResult) -> some View {
        chartCard(title: "Houses", symbol: "building.columns") {
            if r.houseCounts.isEmpty {
                emptyChartNote("Your house spread will show here.")
            } else {
                let top = Array(r.houseCounts.prefix(8))
                Chart(top) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("House", item.house)
                    )
                    .foregroundStyle(Theme.accent.gradient)
                    .cornerRadius(5)
                    .annotation(position: .trailing) {
                        Text("\(item.count)")
                            .font(Theme.rounded(11, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(top.count) * 32 + 10)
                .accessibilityLabel("House distribution bar chart")
            }
        }
    }

    private func wearsOverTimeChart(_ r: StatsResult) -> some View {
        chartCard(title: "Wears over time", symbol: "chart.line.uptrend.xyaxis") {
            Chart(r.wearsOverTime) { point in
                LineMark(
                    x: .value("Month", point.label),
                    y: .value("Wears", point.count)
                )
                .foregroundStyle(Theme.accent)
                .interpolationMethod(.catmullRom)
                PointMark(
                    x: .value("Month", point.label),
                    y: .value("Wears", point.count)
                )
                .foregroundStyle(Theme.accent)
                AreaMark(
                    x: .value("Month", point.label),
                    y: .value("Wears", point.count)
                )
                .foregroundStyle(Theme.accent.opacity(0.12))
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 180)
            .accessibilityLabel("Wears over the last six months line chart")
        }
    }

    private func costPerWearCard(_ r: StatsResult) -> some View {
        chartCard(title: "Cost per wear", symbol: "dollarsign.circle") {
            if r.costPerWear.isEmpty {
                emptyChartNote("Add prices and log wears to rank value here.")
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(r.costPerWear.prefix(8))) { row in
                        HStack {
                            Circle().fill(row.family.hue).frame(width: 10, height: 10)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(row.name)
                                    .font(Theme.rounded(15, .semibold))
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)
                                Text("\(row.house) · \(row.timesWorn) wear\(row.timesWorn == 1 ? "" : "s")")
                                    .font(Theme.rounded(12))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            Spacer()
                            Text(settings.formatMoney(row.costPerWear))
                                .font(Theme.rounded(15, .bold))
                                .foregroundStyle(Theme.accent)
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
    }

    private var neglectedCard: some View {
        let rows = WardrobeEngine.neglected(fragrances: allFragrances, thresholdDays: settings.neglectedDays)
        return chartCard(title: "Neglected (\(settings.neglectedDays)+ days)", symbol: "moon.zzz") {
            if rows.isEmpty {
                emptyChartNote("Nothing neglected — you wear your collection well.")
            } else {
                VStack(spacing: 10) {
                    ForEach(rows.prefix(6)) { row in
                        HStack {
                            Circle().fill(row.family.hue).frame(width: 10, height: 10)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(row.name)
                                    .font(Theme.rounded(15, .semibold))
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)
                                Text(row.house)
                                    .font(Theme.rounded(12))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            Spacer()
                            Text(neglectedLabel(row.lastWorn))
                                .font(Theme.rounded(12, .medium))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                }
            }
        }
    }

    private func neglectedLabel(_ date: Date?) -> String {
        guard let date else { return "Never worn" }
        let days = Calendar.current.dateComponents([.day], from: date, to: .now).day ?? 0
        return "\(days)d ago"
    }

    private var proTeaser: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 34))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Unlock full Scent Stats")
                .font(Theme.serif(20, .semibold))
                .foregroundStyle(Theme.ink)
            Text("Your note-family donut, season & occasion maps, house spread, wears over time, cost-per-wear, and neglected bottles are part of Sillage Pro.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "See Sillage Pro", systemImage: "crown.fill") {
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

    private func emptyChartNote(_ text: String) -> some View {
        Text(text)
            .font(Theme.rounded(14))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Async compute

    @MainActor
    private func recompute() async {
        isLoading = true
        let snapshot = allFragrances
        try? await Task.sleep(nanoseconds: 300_000_000)
        result = StatsEngine.compute(fragrances: snapshot)
        isLoading = false
    }
}
