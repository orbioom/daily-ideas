import SwiftUI
import SwiftData
import Charts

struct ProgressDashboardView: View {
    @Query private var passages: [Passage]
    @Query(sort: \ReviewLog.date, order: .reverse) private var reviews: [ReviewLog]

    private var stats: LibraryStats { LibraryStats.from(passages: passages, reviews: reviews) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if reviews.isEmpty {
                    EmptyStateView(icon: "chart.bar.fill",
                                   title: "No reviews yet",
                                   message: "Study a passage and your streak, mastery and review history will land here.")
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            statsGrid
                            weeklyChart
                            masteryChart
                            recentList
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(value: "\(stats.reviewStreak)", label: "Day streak")
            StatTile(value: "\(stats.passagesMastered)", label: "Mastered", accent: Theme.good)
            StatTile(value: "\(stats.totalReviews)", label: "Reviews", accent: Theme.ink)
            StatTile(value: "\(stats.wordsMemorized)", label: "Words memorized", accent: Theme.good)
            StatTile(value: "\(passages.count)", label: "Passages", accent: Theme.ink)
            StatTile(value: "\(stats.longestStreak)", label: "Longest streak")
        }
    }

    private var weeklyChart: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Label("Reviews per week", systemImage: "calendar")
                    .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                Chart(stats.weeklySeries) { bucket in
                    BarMark(x: .value("Week", bucket.weekStart, unit: .weekOfYear),
                            y: .value("Reviews", bucket.count))
                        .foregroundStyle(Theme.accent)
                        .cornerRadius(4)
                }
                .frame(height: 160)
                .chartYAxis { AxisMarks(position: .leading) }
                .accessibilityLabel("Reviews per week, last eight weeks")
            }
        }
    }

    private var masteryChart: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Label("Mastery distribution", systemImage: "circle.grid.2x2.fill")
                    .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                Chart(Array(stats.masteryDistribution.enumerated()), id: \.offset) { idx, count in
                    BarMark(x: .value("Level", "L\(idx)"),
                            y: .value("Passages", count))
                        .foregroundStyle(idx >= 5 ? Theme.good : Theme.accent)
                        .cornerRadius(4)
                }
                .frame(height: 160)
                .chartYAxis { AxisMarks(position: .leading) }
                .accessibilityLabel("Number of passages at each mastery level zero to five")
            }
        }
    }

    private var recentList: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent reviews").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                let recent = Array(reviews.prefix(12))
                ForEach(Array(recent.enumerated()), id: \.offset) { idx, r in
                    HStack(spacing: 12) {
                        Image(systemName: r.passage?.category.icon ?? "doc.text.fill")
                            .foregroundStyle(Theme.accent).frame(width: 24)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.passage?.title ?? "Deleted passage")
                                .font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                                .lineLimit(1)
                            Text("\(r.level.displayName) · \(Fmt.relativeDay(r.date))")
                                .font(Theme.rounded(12, .regular)).foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Text("\(Int(r.score * 100))%")
                            .font(Theme.rounded(14, .bold)).foregroundStyle(scoreColor(r.score))
                    }
                    .accessibilityElement(children: .combine)
                    if idx < recent.count - 1 { Divider().background(Theme.hairline) }
                }
            }
        }
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 0.8 { return Theme.good }
        if score <= 0.3 { return Theme.bad }
        return Theme.inkSoft
    }
}
