import SwiftUI
import Charts

/// Snapshot of all computed stats, produced off the main render pass.
struct StatsBundle {
    var monthly: [MonthlyStat] = []
    var platforms: [PlatformStat] = []
    var genres: [GenreStat] = []
    var ratings: [RatingBucket] = []
    var totalHours: Double = 0

    var hasRatings: Bool { ratings.contains { $0.count > 0 } }
    var hasMonthlyBeaten: Bool { monthly.contains { $0.beaten > 0 } }
    var hasMonthlyHours: Bool { monthly.contains { $0.hours > 0 } }
}

/// The Charts section. Pure presentation over a precomputed bundle.
struct StatsView: View {
    let bundle: StatsBundle

    var body: some View {
        VStack(spacing: 16) {
            beatenChart
            hoursChart
            platformChart
            genreChart
            ratingChart
        }
    }

    // MARK: Beaten per month

    private var beatenChart: some View {
        SectionCard(title: "Games beaten per month", systemImage: "checkmark.seal.fill") {
            if bundle.hasMonthlyBeaten {
                Chart(bundle.monthly) { stat in
                    BarMark(
                        x: .value("Month", stat.label),
                        y: .value("Beaten", stat.beaten)
                    )
                    .foregroundStyle(Theme.accent)
                    .cornerRadius(4)
                }
                .frame(height: 170)
                .chartYAxis { AxisMarks(position: .leading) }
                .accessibilityLabel("Games beaten per month")
                .accessibilityValue(monthlyBeatenSummary)
            } else {
                miniEmpty("No games beaten yet this year.")
            }
        }
    }

    // MARK: Hours per month

    private var hoursChart: some View {
        SectionCard(title: "Hours played per month", systemImage: "clock.fill") {
            if bundle.hasMonthlyHours {
                Chart(bundle.monthly) { stat in
                    LineMark(
                        x: .value("Month", stat.label),
                        y: .value("Hours", stat.hours)
                    )
                    .foregroundStyle(Theme.accentDeep)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Month", stat.label),
                        y: .value("Hours", stat.hours)
                    )
                    .foregroundStyle(Theme.accent)
                }
                .frame(height: 170)
                .chartYAxis { AxisMarks(position: .leading) }
                .accessibilityLabel("Hours played per month")
                .accessibilityValue(monthlyHoursSummary)
            } else {
                miniEmpty("No sessions logged this year.")
            }
        }
    }

    // MARK: Platform donut

    private var platformChart: some View {
        SectionCard(title: "Library by platform", systemImage: "gamecontroller.fill") {
            if bundle.platforms.isEmpty {
                miniEmpty("No games to chart.")
            } else {
                Chart(bundle.platforms) { stat in
                    SectorMark(
                        angle: .value("Games", stat.count),
                        innerRadius: .ratio(0.58),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("Platform", stat.platform.label))
                    .cornerRadius(3)
                }
                .frame(height: 200)
                .chartLegend(position: .bottom, spacing: 8)
                .accessibilityLabel("Library by platform")
                .accessibilityValue(platformSummary)
            }
        }
    }

    // MARK: Genre bars

    private var genreChart: some View {
        SectionCard(title: "Library by genre", systemImage: "square.stack.3d.up.fill") {
            if bundle.genres.isEmpty {
                miniEmpty("No games to chart.")
            } else {
                Chart(bundle.genres) { stat in
                    BarMark(
                        x: .value("Games", stat.count),
                        y: .value("Genre", stat.genre.label)
                    )
                    .foregroundStyle(Theme.accent.gradient)
                    .cornerRadius(4)
                }
                .frame(height: CGFloat(max(120, bundle.genres.count * 26)))
                .chartXAxis { AxisMarks(position: .bottom) }
                .accessibilityLabel("Library by genre")
                .accessibilityValue(genreSummary)
            }
        }
    }

    // MARK: Rating distribution

    private var ratingChart: some View {
        SectionCard(title: "Rating distribution", systemImage: "star.fill") {
            if bundle.hasRatings {
                Chart(bundle.ratings) { bucket in
                    BarMark(
                        x: .value("Rating", bucket.rating),
                        y: .value("Games", bucket.count)
                    )
                    .foregroundStyle(Theme.warning)
                    .cornerRadius(3)
                }
                .frame(height: 160)
                .chartXScale(domain: 1...10)
                .chartXAxis { AxisMarks(values: Array(1...10)) }
                .accessibilityLabel("Rating distribution from 1 to 10")
                .accessibilityValue(ratingSummary)
            } else {
                miniEmpty("Rate some games to see your distribution.")
            }
        }
    }

    // MARK: Helpers

    private func miniEmpty(_ text: String) -> some View {
        Text(text)
            .font(Theme.rounded(14))
            .foregroundStyle(Theme.textFaint)
            .frame(maxWidth: .infinity, minHeight: 80)
    }

    private var monthlyBeatenSummary: String {
        bundle.monthly.filter { $0.beaten > 0 }
            .map { "\($0.label): \($0.beaten)" }
            .joined(separator: ", ")
    }

    private var monthlyHoursSummary: String {
        bundle.monthly.filter { $0.hours > 0 }
            .map { "\($0.label): \(Int($0.hours.rounded())) hours" }
            .joined(separator: ", ")
    }

    private var platformSummary: String {
        bundle.platforms.map { "\($0.platform.label) \($0.count)" }.joined(separator: ", ")
    }

    private var genreSummary: String {
        bundle.genres.map { "\($0.genre.label) \($0.count)" }.joined(separator: ", ")
    }

    private var ratingSummary: String {
        bundle.ratings.filter { $0.count > 0 }
            .map { "\($0.rating) stars: \($0.count)" }
            .joined(separator: ", ")
    }
}
