import SwiftUI
import SwiftData
import Charts

/// Insights tab. Charts the reader's habits: pages over time (area), books per
/// month (bar), genre distribution (bar), rating distribution (bar), plus streak,
/// pace, and longest-book stat tiles. Calm empty state when nothing is logged.
struct InsightsView: View {
    @Query private var books: [Book]

    private var hasData: Bool {
        !books.isEmpty && books.contains { !$0.sessions.isEmpty || $0.status == .finished }
    }

    private var weekly: [MarginEngine.WeekPages] { MarginEngine.pagesPerWeek(books, weeks: 12) }
    private var monthly: [MarginEngine.MonthCount] { MarginEngine.booksFinishedPerMonth(books) }
    private var genres: [MarginEngine.GenreSlice] { MarginEngine.genreDistribution(books) }
    private var ratings: [MarginEngine.RatingBar] { MarginEngine.ratingDistribution(books) }

    var body: some View {
        NavigationStack {
            ScrollView {
                if !hasData {
                    EmptyStateView(icon: "chart.xyaxis.line",
                                   title: "Nothing to chart yet",
                                   message: "Log a few reading sessions and finish a book — your pages, genres, ratings, and streak will appear here.")
                        .glassCard()
                        .padding(20)
                } else {
                    VStack(spacing: 18) {
                        statsGrid
                        if weekly.contains(where: { $0.pages > 0 }) { pagesChart }
                        if monthly.contains(where: { $0.count > 0 }) { monthlyChart }
                        if !genres.isEmpty { genreChart }
                        if ratings.contains(where: { $0.count > 0 }) { ratingChart }
                        if let longest = MarginEngine.longestBook(books) { longestCard(longest) }
                    }
                    .padding(20)
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("Insights")
            .navigationDestination(for: Book.self) { BookDetailView(book: $0) }
        }
    }

    // MARK: Stats

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(value: "\(MarginEngine.currentStreak(books))", label: "Day streak", tint: Brand.magic)
            StatTile(value: Format.oneDecimal(MarginEngine.pagesPerDay(books, days: 30)), label: "Pages / day")
            StatTile(value: Format.int(MarginEngine.totalPagesThisYear(books)), label: "Pages this year")
            StatTile(value: Format.int(MarginEngine.totalPagesAllTime(books)), label: "Pages all-time")
            if let avg = MarginEngine.averageRating(books) {
                StatTile(value: Format.oneDecimal(avg), label: "Avg rating", tint: Brand.warn)
            } else {
                StatTile(value: "—", label: "Avg rating")
            }
            if let days = MarginEngine.averageDaysToFinish(books) {
                StatTile(value: "\(Int(days.rounded()))d", label: "Avg to finish")
            } else {
                StatTile(value: "—", label: "Avg to finish")
            }
        }
    }

    // MARK: Pages over time (area)

    private var pagesChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Pages per week")
            Chart(weekly) { point in
                AreaMark(
                    x: .value("Week", point.weekStart, unit: .weekOfYear),
                    y: .value("Pages", point.pages)
                )
                .foregroundStyle(
                    LinearGradient(colors: [Brand.magic.opacity(0.45), Brand.magic.opacity(0.05)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .interpolationMethod(.catmullRom)
                LineMark(
                    x: .value("Week", point.weekStart, unit: .weekOfYear),
                    y: .value("Pages", point.pages)
                )
                .foregroundStyle(Brand.magic)
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 190)
            .chartYAxis { AxisMarks(position: .leading) { _ in AxisGridLine(); AxisValueLabel() } }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { _ in
                    AxisValueLabel(format: .dateTime.month(.narrow).day())
                }
            }
            .accessibilityLabel("Area chart of pages read per week over the last twelve weeks")
        }
        .glassCard()
    }

    // MARK: Books per month (bar)

    private var monthlyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Books finished per month")
            Chart(monthly) { point in
                BarMark(
                    x: .value("Month", point.month, unit: .month),
                    y: .value("Books", point.count)
                )
                .foregroundStyle(Brand.live.gradient)
                .cornerRadius(4)
            }
            .frame(height: 180)
            .chartYAxis { AxisMarks(position: .leading) { _ in AxisGridLine(); AxisValueLabel() } }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.narrow))
                }
            }
            .accessibilityLabel("Bar chart of books finished each month this year")
        }
        .glassCard()
    }

    // MARK: Genre distribution (bar)

    private var genreChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Genres read")
            Text("Share of your finished books by genre.")
                .font(.footnote).foregroundStyle(Brand.text3)
            Chart(genres) { slice in
                BarMark(
                    x: .value("Count", slice.count),
                    y: .value("Genre", slice.genre.label)
                )
                .foregroundStyle(Brand.info.gradient)
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("\(slice.count)")
                        .font(Brand.mono(11)).foregroundStyle(Brand.text3)
                }
            }
            .frame(height: CGFloat(max(1, genres.count) * 32 + 24))
            .chartXAxis { AxisMarks { _ in AxisGridLine(); AxisValueLabel() } }
            .accessibilityLabel("Bar chart of finished books by genre")
        }
        .glassCard()
    }

    // MARK: Rating distribution (bar)

    private var ratingChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "How you rate")
            Chart(ratings) { bar in
                BarMark(
                    x: .value("Stars", "\(bar.stars)★"),
                    y: .value("Count", bar.count)
                )
                .foregroundStyle(Brand.warn.gradient)
                .cornerRadius(4)
            }
            .frame(height: 170)
            .chartYAxis { AxisMarks(position: .leading) { _ in AxisGridLine(); AxisValueLabel() } }
            .accessibilityLabel("Bar chart of how many books received each star rating")
        }
        .glassCard()
    }

    // MARK: Longest book

    private func longestCard(_ book: Book) -> some View {
        NavigationLink(value: book) {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "Longest book")
                HStack(spacing: 14) {
                    BookSpine(book: book)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.title).font(.headline).foregroundStyle(Brand.text).lineLimit(2)
                        Text(book.author).font(.subheadline).foregroundStyle(Brand.text2).lineLimit(1)
                        Text("\(Format.int(book.totalPages)) pages")
                            .font(Brand.mono(13, weight: .semibold)).foregroundStyle(Brand.magic)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Brand.text3)
                        .accessibilityHidden(true)
                }
            }
            .glassCard()
        }
        .buttonStyle(.plain)
    }
}
