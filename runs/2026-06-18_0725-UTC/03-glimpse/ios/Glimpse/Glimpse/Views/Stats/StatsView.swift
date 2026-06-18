import SwiftUI
import SwiftData
import Charts

/// Swift Charts insights: streak summary, moments/month bars, mood donut,
/// top tags.
struct StatsView: View {
    @Query(sort: \Moment.createdAt, order: .reverse) private var moments: [Moment]

    private var summary: StatsSummary { StatsEngine.summary(moments: moments) }
    private var streak: StreakStats { StreakEngine.compute(moments: moments) }

    var body: some View {
        NavigationStack {
            Group {
                if moments.isEmpty {
                    EmptyStateView(
                        symbol: "chart.bar",
                        title: "Insights are coming",
                        message: "Capture a few moments and your streaks, moods and patterns will appear here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            metricRow
                            monthsCard
                            moodCard
                            tagsCard
                        }
                        .padding(16)
                    }
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Stats")
        }
    }

    private var metricRow: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            StatTile(value: "\(streak.current)", label: "Current streak", symbol: "flame.fill", tint: Theme.accent)
            StatTile(value: "\(summary.longestStreak)", label: "Longest streak", symbol: "trophy.fill", tint: Theme.warn)
            StatTile(value: "\(summary.distinctDays)", label: "Days captured", symbol: "calendar", tint: Theme.good)
            StatTile(value: "\(summary.photoCount)", label: "Photos", symbol: "photo.fill", tint: Mood.rough.color)
        }
    }

    private var monthsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Moments per month", subtitle: "Last 6 months")
            Chart(summary.monthCounts) { item in
                BarMark(
                    x: .value("Month", item.label),
                    y: .value("Moments", item.count)
                )
                .foregroundStyle(Theme.accent.gradient)
                .cornerRadius(6)
                .accessibilityLabel(item.label)
                .accessibilityValue("\(item.count) moments")
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 200)
        }
        .padding(16)
        .cardSurface()
    }

    private var moodCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Mood distribution", subtitle: "Across all moments")
            if summary.moodSlices.isEmpty {
                Text("No moods recorded yet.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.inkSoft)
            } else {
                HStack(alignment: .center, spacing: 18) {
                    Chart(summary.moodSlices) { slice in
                        SectorMark(
                            angle: .value("Count", slice.count),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .foregroundStyle(slice.mood.color)
                        .cornerRadius(3)
                        .accessibilityLabel(slice.mood.label)
                        .accessibilityValue("\(slice.count)")
                    }
                    .frame(width: 150, height: 150)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(summary.moodSlices) { slice in
                            HStack(spacing: 8) {
                                Circle().fill(slice.mood.color).frame(width: 10, height: 10)
                                Text(slice.mood.label)
                                    .font(Theme.rounded(13, .medium))
                                    .foregroundStyle(Theme.ink)
                                Spacer()
                                Text("\(slice.count)")
                                    .font(Theme.rounded(13, .semibold))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .cardSurface()
    }

    private var tagsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Top tags", subtitle: "Your recurring threads")
            if summary.topTags.isEmpty {
                Text("Add tags to your moments to see patterns here.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.inkSoft)
            } else {
                Chart(summary.topTags) { tag in
                    BarMark(
                        x: .value("Count", tag.count),
                        y: .value("Tag", tag.tag)
                    )
                    .foregroundStyle(Theme.heroGradient)
                    .cornerRadius(5)
                    .annotation(position: .trailing) {
                        Text("\(tag.count)")
                            .font(Theme.rounded(11, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .accessibilityLabel(tag.tag)
                    .accessibilityValue("\(tag.count) moments")
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(summary.topTags.count) * 40 + 10)
            }
        }
        .padding(16)
        .cardSurface()
    }
}

struct StatTile: View {
    let value: String
    let label: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(Theme.rounded(13, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
