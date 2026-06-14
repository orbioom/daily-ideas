import SwiftUI
import SwiftData
import Charts

/// Stats — Swift Charts computed async with a loading state; full charts gated behind Pro.
struct StatsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var allRecords: [Record]

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
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
        }
        .task(id: dataSignature) { await recompute() }
    }

    /// Recompute whenever the underlying data meaningfully changes.
    private var dataSignature: String {
        let records = allRecords.count
        let spins = allRecords.reduce(0) { $0 + $1.spins.count }
        let value = allRecords.reduce(0.0) { $0 + $1.estValue }
        return "\(records)-\(spins)-\(Int(value))"
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack(spacing: 14) {
                ProgressView().controlSize(.large).tint(Theme.accent)
                Text("Counting the crate…")
                    .font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
            }
            .accessibilityLabel("Computing statistics")
        } else if let result, !result.isEmpty {
            ScrollView {
                VStack(spacing: 16) {
                    summaryGrid(result)
                    if isPro {
                        genreDonut(result)
                        decadeChart(result)
                        formatChart(result)
                        conditionChart(result)
                        spinsOverTimeChart(result)
                        valueByGenreChart(result)
                        mostSpunCard(result)
                    } else {
                        proTeaser
                    }
                }
                .padding(20)
            }
        } else {
            EmptyStateView(symbol: "chart.bar.xaxis",
                           title: "No stats yet",
                           message: "Add some records — or load the sample collection from Settings — and your crate's stats appear here.")
        }
    }

    // MARK: Summary (free)

    private func summaryGrid(_ r: StatsResult) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard("Records", "\(r.ownedCount)", "square.stack.3d.up")
            if settings.hideValues {
                statCard("On wantlist", "\(r.wantlistCount)", "bookmark")
            } else {
                statCard("Collection value", settings.formatMoney(r.collectionValue), "dollarsign.circle")
            }
            statCard("Total spins", "\(r.totalSpins)", "play.circle")
            statCard("Spins this month", "\(r.spinsThisMonth)", "calendar")
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

    private func genreDonut(_ r: StatsResult) -> some View {
        chartCard(title: "Genres in your crate", symbol: "guitars") {
            let top = Array(r.byGenre.prefix(8))
            if top.isEmpty {
                emptyChartNote("Add records with genres to see this.")
            } else {
                HStack(spacing: 16) {
                    Chart(top) { item in
                        SectorMark(
                            angle: .value("Count", item.count),
                            innerRadius: .ratio(0.58),
                            angularInset: 1.5
                        )
                        .foregroundStyle(item.genre?.hue ?? Theme.accent)
                        .cornerRadius(3)
                    }
                    .frame(width: 150, height: 150)
                    .accessibilityLabel("Genre distribution donut chart")

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(top) { item in
                            HStack(spacing: 6) {
                                Circle().fill(item.genre?.hue ?? Theme.accent).frame(width: 9, height: 9)
                                Text(item.label).font(Theme.rounded(12)).foregroundStyle(Theme.ink)
                                Spacer(minLength: 4)
                                Text("\(item.count)").font(Theme.rounded(12, .semibold)).foregroundStyle(Theme.inkSoft)
                            }
                        }
                    }
                }
            }
        }
    }

    private func decadeChart(_ r: StatsResult) -> some View {
        chartCard(title: "By decade", symbol: "calendar") {
            if r.byDecade.isEmpty {
                emptyChartNote("Add release years to chart decades.")
            } else {
                Chart(r.byDecade) { item in
                    BarMark(x: .value("Decade", item.label), y: .value("Count", item.count))
                        .foregroundStyle(Theme.accent.gradient)
                        .cornerRadius(5)
                        .annotation(position: .top) {
                            Text("\(item.count)").font(Theme.rounded(10, .semibold)).foregroundStyle(Theme.inkSoft)
                        }
                }
                .frame(height: 200)
                .accessibilityLabel("Records by decade bar chart")
            }
        }
    }

    private func formatChart(_ r: StatsResult) -> some View {
        chartCard(title: "Formats", symbol: "opticaldisc") {
            Chart(r.byFormat) { item in
                BarMark(x: .value("Count", item.count), y: .value("Format", item.label))
                    .foregroundStyle(Theme.accent.gradient)
                    .cornerRadius(5)
                    .annotation(position: .trailing) {
                        Text("\(item.count)").font(Theme.rounded(10, .semibold)).foregroundStyle(Theme.inkSoft)
                    }
            }
            .chartXAxis(.hidden)
            .frame(height: CGFloat(max(1, r.byFormat.count)) * 32 + 12)
            .accessibilityLabel("Format breakdown bar chart")
        }
    }

    private func conditionChart(_ r: StatsResult) -> some View {
        chartCard(title: "Condition (media)", symbol: "checkmark.seal") {
            Chart(r.byCondition) { item in
                BarMark(x: .value("Grade", item.label), y: .value("Count", item.count))
                    .foregroundStyle(Theme.good.gradient)
                    .cornerRadius(4)
            }
            .frame(height: 180)
            .accessibilityLabel("Condition distribution bar chart")
        }
    }

    private func spinsOverTimeChart(_ r: StatsResult) -> some View {
        chartCard(title: "Spins over time", symbol: "waveform.path.ecg") {
            if r.totalSpins == 0 {
                emptyChartNote("Log some spins to see your listening over time.")
            } else {
                Chart(r.spinsOverTime) { pt in
                    LineMark(x: .value("Month", pt.month, unit: .month), y: .value("Spins", pt.count))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Theme.accent)
                    AreaMark(x: .value("Month", pt.month, unit: .month), y: .value("Spins", pt.count))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Theme.accent.opacity(0.15))
                    PointMark(x: .value("Month", pt.month, unit: .month), y: .value("Spins", pt.count))
                        .foregroundStyle(Theme.accent)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month, count: 2)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.narrow))
                    }
                }
                .frame(height: 190)
                .accessibilityLabel("Spins over the last 12 months line chart")
            }
        }
    }

    private func valueByGenreChart(_ r: StatsResult) -> some View {
        chartCard(title: "Value by genre", symbol: "dollarsign.circle") {
            if settings.hideValues {
                emptyChartNote("Values are hidden. Turn off \"Hide values\" in Settings to show this.")
            } else if r.valueByGenre.isEmpty {
                emptyChartNote("Add estimated values to your records to chart this.")
            } else {
                let top = Array(r.valueByGenre.prefix(8))
                Chart(top) { item in
                    BarMark(x: .value("Value", item.value), y: .value("Genre", item.label))
                        .foregroundStyle(item.genre?.hue ?? Theme.accent)
                        .cornerRadius(5)
                        .annotation(position: .trailing) {
                            Text(settings.formatMoney(item.value))
                                .font(Theme.rounded(10, .semibold)).foregroundStyle(Theme.inkSoft)
                        }
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(top.count) * 34 + 12)
                .accessibilityLabel("Value by genre bar chart")
            }
        }
    }

    private func mostSpunCard(_ r: StatsResult) -> some View {
        chartCard(title: "Most spun", symbol: "flame.fill") {
            if r.mostSpun.isEmpty {
                emptyChartNote("Log spins and your most-played records appear here.")
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(r.mostSpun.enumerated()), id: \.element.id) { idx, item in
                        HStack(spacing: 10) {
                            Text("\(idx + 1)")
                                .font(Theme.rounded(13, .bold))
                                .foregroundStyle(Theme.inkFaint)
                                .frame(width: 18)
                            CoverArtView(title: item.title, artist: item.artist, hue: item.coverHue, showDisc: false)
                                .frame(width: 38, height: 38)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.title).font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.ink).lineLimit(1)
                                Text(item.artist).font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft).lineLimit(1)
                            }
                            Spacer()
                            Text("\(item.spins)×")
                                .font(Theme.rounded(14, .bold))
                                .foregroundStyle(Theme.accent)
                                .monospacedDigit()
                        }
                    }
                    HStack {
                        Image(systemName: "moon.zzz")
                            .font(.system(size: 12)).foregroundStyle(Theme.inkFaint)
                        Text("\(r.neverSpunCount) owned record\(r.neverSpunCount == 1 ? "" : "s") never spun · avg \(String(format: "%.1f", r.averageTrackCount)) tracks")
                            .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private var proTeaser: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 34)).foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Unlock the full Stats room")
                .font(Theme.serif(20, .semibold)).foregroundStyle(Theme.ink)
            Text("Genre donut, by-decade and format breakdowns, condition distribution, spins-over-time, value-by-genre and your most-spun shelf are part of Crate Pro.")
                .font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "See Crate Pro", systemImage: "crown.fill") {
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
        let snapshot = allRecords
        try? await Task.sleep(nanoseconds: 320_000_000)
        result = StatsEngine.compute(records: snapshot)
        isLoading = false
    }
}
