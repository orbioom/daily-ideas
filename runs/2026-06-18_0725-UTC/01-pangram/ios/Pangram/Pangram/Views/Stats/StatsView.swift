import SwiftUI
import SwiftData
import Charts

/// Analytics screen: words over time, score distribution, pangrams, Genius rate, streaks.
struct StatsView: View {
    @Query(sort: \DailyResult.date, order: .forward) private var results: [DailyResult]
    @EnvironmentObject private var pro: ProStore
    @State private var showPaywall = false

    private var currentStreak: Int { StreakCalculator.currentStreak(from: results) }
    private var longestStreak: Int { StreakCalculator.longestStreak(from: results) }
    private var geniusRate: Double { StreakCalculator.geniusRate(from: results) }
    private var totalPangrams: Int { StreakCalculator.totalPangrams(from: results) }
    private var totalWords: Int { StreakCalculator.totalWords(from: results) }

    /// Free users see a recent window; Pro sees full history.
    private var visible: [DailyResult] {
        pro.isPro ? results : Array(results.suffix(7))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if results.isEmpty {
                    EmptyStateView(
                        symbol: "chart.bar.xaxis",
                        title: "No stats yet",
                        message: "Play your first Daily and your progress will start charting here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            summaryGrid
                            wordsChart
                            scoreDistributionChart
                            pangramChart
                            if !pro.isPro { proNote }
                        }
                        .padding(18)
                    }
                }
            }
            .navigationTitle("Stats")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var summaryGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 14) {
            statCard("Days played", "\(results.count)", "calendar")
            statCard("Total words", "\(totalWords)", "text.book.closed.fill")
            statCard("Pangrams", "\(totalPangrams)", "star.fill")
            statCard("Genius rate", "\(Int((geniusRate * 100).rounded()))%", "brain.head.profile")
            statCard("Current streak", "\(currentStreak)", "flame.fill")
            statCard("Longest streak", "\(longestStreak)", "trophy.fill")
        }
    }

    private func statCard(_ label: String, _ value: String, _ symbol: String) -> some View {
        SectionCard {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 30)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(Theme.rounded(20, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(label)
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var wordsChart: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 10) {
                chartTitle("Words found over time")
                Chart(visible) { r in
                    LineMark(
                        x: .value("Date", r.date),
                        y: .value("Words", r.wordsFound)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Theme.accent)
                    AreaMark(
                        x: .value("Date", r.date),
                        y: .value("Words", r.wordsFound)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.accent.opacity(0.35), Theme.accent.opacity(0.02)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                }
                .frame(height: 180)
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
                .accessibilityLabel("Line chart of words found per day")
                .accessibilityValue("\(visible.count) days shown, latest \(visible.last?.wordsFound ?? 0) words")
            }
        }
    }

    private var scoreDistributionChart: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 10) {
                chartTitle("Score by day")
                Chart(visible) { r in
                    BarMark(
                        x: .value("Date", r.date, unit: .day),
                        y: .value("Score", r.score)
                    )
                    .foregroundStyle(r.reachedGenius ? Theme.accentDeep : Theme.accent.opacity(0.7))
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
                .accessibilityLabel("Bar chart of daily scores; darker bars are Genius days")
                .accessibilityValue("\(visible.count) days shown")
            }
        }
    }

    private var pangramChart: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 10) {
                chartTitle("Pangrams per day")
                Chart(visible) { r in
                    BarMark(
                        x: .value("Date", r.date, unit: .day),
                        y: .value("Pangrams", r.pangrams)
                    )
                    .foregroundStyle(Theme.heroGradient)
                    .cornerRadius(4)
                }
                .frame(height: 150)
                .chartYAxis { AxisMarks(values: .automatic(desiredCount: 3)) }
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
                .accessibilityLabel("Bar chart of pangrams found per day")
                .accessibilityValue("Total \(totalPangrams) pangrams")
            }
        }
    }

    private func chartTitle(_ text: String) -> some View {
        Text(text)
            .font(Theme.rounded(16, .bold))
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var proNote: some View {
        Button {
            showPaywall = true
        } label: {
            SectionCard {
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Theme.accentDeep)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Showing last 7 days")
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("Unlock Pro for your full history.")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.inkSoft)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the Pro upgrade screen")
    }
}
