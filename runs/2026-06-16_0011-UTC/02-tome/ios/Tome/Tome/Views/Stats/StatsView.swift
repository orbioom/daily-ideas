import SwiftUI
import SwiftData
import Charts

/// Reading stats — Swift Charts computed async with a loading state. Pro gates the deeper charts.
struct StatsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var allBooks: [Book]

    @State private var stats: ReadingStats?
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

    /// Recompute when the underlying data meaningfully changes.
    private var dataSignature: String {
        let books = allBooks.count
        let pages = allBooks.reduce(0) { $0 + $1.currentPage }
        let finished = allBooks.filter { $0.shelf == .finished }.count
        let sessions = allBooks.reduce(0) { $0 + $1.sessions.count }
        return "\(books)-\(pages)-\(finished)-\(sessions)-\(settings.readingGoal)"
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack(spacing: 14) {
                ProgressView().controlSize(.large).tint(Theme.accent)
                Text("Turning the pages…")
                    .font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
            }
            .accessibilityLabel("Computing statistics")
        } else if let stats, !stats.isEmpty {
            ScrollView {
                VStack(spacing: 16) {
                    challengeGauge(stats)
                    summaryGrid(stats)
                    pagesPerMonthChart(stats)
                    if isPro {
                        genreDonut(stats)
                        ratingsHistogram(stats)
                        paceCard(stats)
                    } else {
                        proTeaser
                    }
                }
                .padding(20)
            }
        } else {
            EmptyStateView(symbol: "chart.pie",
                           title: "No stats yet",
                           message: "Log some reading sessions and finish a book or two — your reading year will appear here.")
        }
    }

    // MARK: - Challenge gauge

    private func challengeGauge(_ s: ReadingStats) -> some View {
        chartCard(title: "Reading Challenge", symbol: "flag.checkered") {
            HStack(spacing: 20) {
                ProgressRing(progress: s.goalProgress, lineWidth: 12,
                             label: "\(s.booksFinishedThisYear)/\(s.readingGoal)")
                    .frame(width: 96, height: 96)
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(Int(s.goalProgress * 100))% of your goal")
                        .font(Theme.rounded(17, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(s.readingGoal > s.booksFinishedThisYear
                         ? "\(s.readingGoal - s.booksFinishedThisYear) books to go this year."
                         : "Goal reached — wonderful!")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Summary (free)

    private func summaryGrid(_ s: ReadingStats) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatChip(caption: "Pages read", value: "\(s.totalPagesRead)", systemImage: "doc.text.fill")
            StatChip(caption: "Finished this year", value: "\(s.booksFinishedThisYear)", systemImage: "checkmark.seal.fill")
            StatChip(caption: "Longest streak", value: "\(s.longestStreak) days", systemImage: "flame.fill")
            StatChip(caption: "Avg rating",
                     value: s.ratedCount > 0 ? String(format: "%.1f★", s.averageRating) : "—",
                     systemImage: "star.fill")
        }
    }

    // MARK: - Pages per month (free)

    private func pagesPerMonthChart(_ s: ReadingStats) -> some View {
        chartCard(title: "Pages per month", symbol: "calendar") {
            Chart(s.pagesPerMonth) { item in
                BarMark(
                    x: .value("Month", item.label),
                    y: .value("Pages", item.pages)
                )
                .foregroundStyle(Theme.accent.gradient)
                .cornerRadius(4)
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 200)
            .accessibilityLabel("Pages read per month this year")
        }
    }

    // MARK: - Genre donut (Pro)

    private func genreDonut(_ s: ReadingStats) -> some View {
        chartCard(title: "By genre", symbol: "books.vertical") {
            let top = Array(s.genreCounts.prefix(8))
            if top.isEmpty {
                emptyChartNote("Tag your books to see a genre breakdown.")
            } else {
                Chart(top) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.58),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("Genre", item.label))
                    .cornerRadius(3)
                }
                .chartLegend(position: .bottom, spacing: 10)
                .frame(height: 240)
                .accessibilityLabel("Genre distribution donut chart")
            }
        }
    }

    // MARK: - Ratings histogram (Pro)

    private func ratingsHistogram(_ s: ReadingStats) -> some View {
        chartCard(title: "Ratings", symbol: "star.leadinghalf.filled") {
            if s.ratedCount == 0 {
                emptyChartNote("Rate a few finished books to fill this in.")
            } else {
                Chart(s.ratingHistogram) { bin in
                    BarMark(
                        x: .value("Rating", bin.label),
                        y: .value("Count", bin.count)
                    )
                    .foregroundStyle(Theme.accent.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .accessibilityLabel("Ratings histogram, one to five stars")
            }
        }
    }

    // MARK: - Pace (Pro)

    private func paceCard(_ s: ReadingStats) -> some View {
        chartCard(title: "Pace & finishing", symbol: "speedometer") {
            VStack(spacing: 12) {
                paceRow("Avg days to finish a book",
                        s.averageDaysToFinish > 0 ? "\(Int(s.averageDaysToFinish.rounded())) days" : "—",
                        "calendar.badge.clock")
                Divider().overlay(Theme.hairline)
                paceRow("Currently reading", "\(s.currentlyReading) books", "book")
                Divider().overlay(Theme.hairline)
                paceRow("Daily page target", "\(settings.pagesPerDayTarget) pp/day", "target")
            }
        }
    }

    private func paceRow(_ title: String, _ value: String, _ symbol: String) -> some View {
        HStack {
            Label(title, systemImage: symbol)
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value)
                .font(Theme.rounded(15, .bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Pro teaser

    private var proTeaser: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 34)).foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Unlock your full reading stats")
                .font(Theme.serif(20, .semibold))
                .foregroundStyle(Theme.ink)
            Text("Genre breakdowns, your ratings histogram, and reading pace with finish projections are part of Tome Pro.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "See Tome Pro", systemImage: "crown.fill") {
                paywallReason = .stats
            }
        }
        .padding(22)
        .cardSurface()
    }

    // MARK: - Helpers

    private func emptyChartNote(_ text: String) -> some View {
        Text(text)
            .font(Theme.rounded(14))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }

    private func chartCard<Content: View>(title: String, symbol: String,
                                          @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(Theme.serif(18, .semibold))
                .foregroundStyle(Theme.ink)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    @MainActor
    private func recompute() async {
        isLoading = true
        let snapshot = allBooks
        let goal = settings.readingGoal
        // Brief delay so the loading state is perceptible.
        try? await Task.sleep(nanoseconds: 300_000_000)
        stats = ReadingEngine.computeStats(books: snapshot, goal: goal)
        isLoading = false
    }
}
