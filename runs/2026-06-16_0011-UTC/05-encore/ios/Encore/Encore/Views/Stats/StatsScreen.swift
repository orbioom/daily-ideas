import SwiftUI
import SwiftData
import Charts

/// Stats — Swift Charts computed in an async @MainActor pass with a loading state.
/// Free tier sees the summary; Pro unlocks the full charts and the Wrapped share card.
struct StatsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var concerts: [Concert]

    @State private var stats: ConcertStats?
    @State private var isLoading = false
    @State private var paywallReason: PaywallReason?
    @State private var showWrapped = false

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
                        Button { paywallReason = .fullStats } label: {
                            Label("Pro", systemImage: "crown.fill")
                                .font(Theme.rounded(13, .semibold))
                        }
                    }
                }
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(isPresented: $showWrapped) {
                if let stats {
                    WrappedShareSheet(stats: stats)
                }
            }
        }
        .task(id: dataSignature) { await recompute() }
    }

    /// Recompute whenever the data meaningfully changes.
    private var dataSignature: String {
        let count = concerts.count
        let ratingSum = concerts.compactMap { $0.rating }.reduce(0, +)
        let songCount = concerts.reduce(0) { $0 + $1.setlist.count }
        return "\(count)-\(ratingSum)-\(songCount)"
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack(spacing: 14) {
                ProgressView().controlSize(.large).tint(Theme.accent)
                Text("Counting your shows…")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
            }
            .accessibilityLabel("Computing statistics")
        } else if let stats, !stats.isEmpty {
            ScrollView {
                VStack(spacing: 16) {
                    summaryGrid(stats)
                    highlightsCard(stats)
                    if isPro {
                        wrappedTeaser(stats)
                        showsPerYearChart(stats)
                        topArtistsChart(stats)
                        topVenuesChart(stats)
                        genreDonut(stats)
                        spendChart(stats)
                    } else {
                        proTeaser
                    }
                }
                .padding(20)
            }
        } else {
            EmptyStateView(symbol: "chart.bar.xaxis",
                           title: "No stats yet",
                           message: "Log a few shows and your concert stats — top artists, venues, genres and spend — appear here.")
        }
    }

    // MARK: Summary (free)

    private func summaryGrid(_ s: ConcertStats) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(caption: "Shows", value: "\(s.totalAttended)", systemImage: "ticket.fill")
            StatCard(caption: "Artists", value: "\(s.distinctArtists)", systemImage: "music.mic")
            StatCard(caption: "Venues", value: "\(s.distinctVenues)", systemImage: "building.2.fill")
            StatCard(caption: "Cities", value: "\(s.distinctCities)", systemImage: "map.fill")
            StatCard(caption: "Avg rating",
                     value: s.ratedCount > 0 ? String(format: "%.1f", s.averageRating) : "—",
                     systemImage: "star.fill")
            StatCard(caption: "Total spent", value: settings.money(s.totalSpent), systemImage: "creditcard.fill")
        }
    }

    private func highlightsCard(_ s: ConcertStats) -> some View {
        chartCard(title: "Highlights", symbol: "sparkles") {
            VStack(alignment: .leading, spacing: 12) {
                highlightRow("Most-seen artist",
                             s.mostSeenArtist.map { "\($0.label) (\($0.count)×)" } ?? "—")
                highlightRow("Most-visited venue",
                             s.mostVisitedVenue.map { "\($0.label) (\($0.count)×)" } ?? "—")
                highlightRow("Busiest year", s.busiestYear.map(String.init) ?? "—")
                highlightRow("First show",
                             s.firstShowDate.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "—")
                highlightRow("Songs logged", "\(s.totalSongsLogged)")
            }
        }
    }

    private func highlightRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value)
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Pro — Wrapped

    private func wrappedTeaser(_ s: ConcertStats) -> some View {
        Button {
            showWrapped = true
            Haptics.tap(enabled: settings.hapticsEnabled)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "rectangle.stack.badge.play.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Concert Wrapped")
                        .font(Theme.rounded(17, .bold))
                        .foregroundStyle(.white)
                    Text("Your year in live music — tap to share")
                        .font(Theme.rounded(13))
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.9))
                    .accessibilityHidden(true)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.heroGradient))
        }
        .buttonStyle(PressableScale())
        .accessibilityLabel("Open Concert Wrapped share card")
    }

    // MARK: Pro charts

    private func showsPerYearChart(_ s: ConcertStats) -> some View {
        chartCard(title: "Shows per year", symbol: "calendar") {
            Chart(s.showsPerYear) { item in
                BarMark(
                    x: .value("Year", item.label),
                    y: .value("Shows", item.count)
                )
                .foregroundStyle(Theme.accent.gradient)
                .cornerRadius(5)
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 200)
            .accessibilityLabel("Shows per year bar chart")
        }
    }

    private func topArtistsChart(_ s: ConcertStats) -> some View {
        chartCard(title: "Top artists", symbol: "music.mic") {
            let top = Array(s.topArtists.prefix(8))
            Chart(top) { item in
                BarMark(
                    x: .value("Times seen", item.count),
                    y: .value("Artist", item.label)
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
            .frame(height: CGFloat(max(top.count, 1)) * 34 + 10)
            .accessibilityLabel("Top artists bar chart")
        }
    }

    private func topVenuesChart(_ s: ConcertStats) -> some View {
        chartCard(title: "Top venues", symbol: "building.2") {
            let top = Array(s.topVenues.prefix(8))
            if top.isEmpty {
                emptyChartNote("Add venue names to see your most-visited spots.")
            } else {
                Chart(top) { item in
                    BarMark(
                        x: .value("Times", item.count),
                        y: .value("Venue", item.label)
                    )
                    .foregroundStyle(Theme.purple.gradient)
                    .cornerRadius(5)
                    .annotation(position: .trailing) {
                        Text("\(item.count)")
                            .font(Theme.rounded(11, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(top.count) * 34 + 10)
                .accessibilityLabel("Top venues bar chart")
            }
        }
    }

    private func genreDonut(_ s: ConcertStats) -> some View {
        chartCard(title: "Genres", symbol: "guitars") {
            let top = Array(s.genreCounts.prefix(8))
            if top.isEmpty {
                emptyChartNote("Tag your shows with genres to see your mix.")
            } else {
                VStack(spacing: 12) {
                    let palette = donutPalette(count: top.count)
                    Chart(top) { item in
                        SectorMark(
                            angle: .value("Count", item.count),
                            innerRadius: .ratio(0.58),
                            angularInset: 1.5
                        )
                        .cornerRadius(4)
                        .foregroundStyle(by: .value("Genre", item.label))
                    }
                    .chartForegroundStyleScale(domain: top.map { $0.label }, range: palette)
                    .frame(height: 200)
                    .accessibilityLabel("Genre distribution donut chart")

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(Array(top.enumerated()), id: \.element.id) { idx, item in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(palette[safe: idx] ?? Theme.accent)
                                    .frame(width: 8, height: 8)
                                Text("\(item.label) · \(item.count)")
                                    .font(Theme.rounded(12))
                                    .foregroundStyle(Theme.inkSoft)
                                    .lineLimit(1)
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }

    private func spendChart(_ s: ConcertStats) -> some View {
        chartCard(title: "Spend over time", symbol: "creditcard") {
            let series = s.spendPerYear
            if series.isEmpty {
                emptyChartNote("Add ticket prices to track your spend.")
            } else {
                Chart(series) { item in
                    LineMark(
                        x: .value("Year", item.label),
                        y: .value("Spent", NSDecimalNumber(decimal: item.total).doubleValue)
                    )
                    .foregroundStyle(Theme.accent)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Year", item.label),
                        y: .value("Spent", NSDecimalNumber(decimal: item.total).doubleValue)
                    )
                    .foregroundStyle(Theme.accent)
                    AreaMark(
                        x: .value("Year", item.label),
                        y: .value("Spent", NSDecimalNumber(decimal: item.total).doubleValue)
                    )
                    .foregroundStyle(Theme.accent.opacity(0.15))
                    .interpolationMethod(.catmullRom)
                }
                .chartYAxis { AxisMarks(position: .leading) }
                .frame(height: 200)
                .accessibilityLabel("Spend over time line chart")
            }
        }
    }

    private var proTeaser: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 34))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Unlock your full Stats")
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.ink)
            Text("Shows per year, top artists and venues, your genre mix, spend over time, and the Concert Wrapped share card are part of Encore Pro.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "See Encore Pro", systemImage: "crown.fill") {
                paywallReason = .fullStats
            }
        }
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    /// A stable colour ramp for the genre donut + legend.
    private func donutPalette(count: Int) -> [Color] {
        let base: [Color] = [
            Color(hex: 0xC2459B), Color(hex: 0x7A3FC0), Color(hex: 0xE05CB4),
            Color(hex: 0x5C3FC0), Color(hex: 0xD1487A), Color(hex: 0x8A2EAE),
            Color(hex: 0xE0708A), Color(hex: 0x3F4FC0)
        ]
        guard count > 0 else { return base }
        if count <= base.count { return Array(base.prefix(count)) }
        return (0..<count).map { base[$0 % base.count] }
    }

    private func emptyChartNote(_ text: String) -> some View {
        Text(text)
            .font(Theme.rounded(14))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chartCard<Content: View>(title: String, symbol: String,
                                          @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(Theme.ink)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    // MARK: Async compute

    @MainActor
    private func recompute() async {
        isLoading = true
        let snapshot = concerts
        try? await Task.sleep(nanoseconds: 300_000_000)
        stats = ConcertStatsEngine.compute(concerts: snapshot)
        isLoading = false
    }
}

/// Renders and shares the Concert Wrapped card.
private struct WrappedShareSheet: View {
    let stats: ConcertStats
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var rendered: ShareableImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    WrappedCardView(stats: stats, settings: settings)
                        .padding(.top, 12)
                    if let rendered {
                        ShareLink(item: rendered,
                                  preview: SharePreview("My Concert Wrapped",
                                                        image: Image(uiImage: rendered.image))) {
                            Label("Share Wrapped", systemImage: "square.and.arrow.up")
                                .font(Theme.rounded(16, .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.heroGradient))
                        }
                        .padding(.horizontal, 24)
                    } else {
                        ProgressView().tint(Theme.accent)
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Concert Wrapped")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
        .task { await render() }
    }

    @MainActor
    private func render() {
        let card = WrappedCardView(stats: stats, settings: settings)
        if let image = ImageExport.render(card) {
            rendered = ShareableImage(image: image)
        }
    }
}

#Preview("Stats") {
    StatsScreen()
        .environmentObject(AppSettings())
        .modelContainer(PreviewContainer.shared)
}
