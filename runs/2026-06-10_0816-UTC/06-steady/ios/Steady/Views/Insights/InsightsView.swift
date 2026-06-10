import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \ThoughtRecord.createdAt, order: .reverse) private var records: [ThoughtRecord]
    @Query(sort: \MoodLog.date, order: .reverse) private var moods: [MoodLog]
    @State private var insights: SteadyInsights?

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if let insights {
                    if insights.recordCount == 0 && moods.isEmpty {
                        EmptyStateView(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Nothing to show yet",
                            message: "Finish a thought record or log a mood — Steady starts charting your patterns from the first one."
                        )
                    } else {
                        content(insights)
                    }
                } else {
                    ProgressView("Reading your patterns…")
                        .tint(Brand.text2)
                        .foregroundStyle(Brand.text2)
                }
            }
            .navigationTitle("Insights")
            .task(id: "\(records.count)-\(moods.count)") {
                insights = InsightEngine.compute(records: records, moods: moods)
            }
        }
    }

    private func content(_ insights: SteadyInsights) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    bigStat("\(insights.totalReframes)", "reframes")
                    bigStat(insights.avgBeliefDrop > 0 ? "−\(Int(insights.avgBeliefDrop.rounded()))%" : "—", "avg belief drop")
                    bigStat("\(insights.streak)", "day streak")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "Mood · last 30 days")
                    let points = insights.moodTrend.filter { $0.score != nil }
                    if points.count < 2 {
                        Text("A few more days of check-ins and the trend line appears.")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text3)
                    } else {
                        Chart(points) { p in
                            LineMark(
                                x: .value("Day", p.day, unit: .day),
                                y: .value("Mood", p.score ?? 0)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Brand.live)
                            PointMark(
                                x: .value("Day", p.day, unit: .day),
                                y: .value("Mood", p.score ?? 0)
                            )
                            .foregroundStyle(Brand.live)
                            .symbolSize(20)
                        }
                        .chartYScale(domain: 1...5)
                        .chartYAxis {
                            AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let v = value.as(Int.self) {
                                        Text(["", "😟", "🙁", "😐", "🙂", "😄"][v])
                                    }
                                }
                            }
                        }
                        .frame(height: 170)
                        Text("Mood check-ins plus how you felt after each reframe.")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    }
                }
                .glassCard()
                .accessibilityLabel("Line chart of mood over the last 30 days")

                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "Your thinking traps")
                    if insights.topDistortions.isEmpty {
                        Text("No traps tagged yet — they show up here once you spot them in records.")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text3)
                    } else {
                        Chart(insights.topDistortions.prefix(6)) { row in
                            BarMark(
                                x: .value("Count", row.count),
                                y: .value("Trap", row.distortion.name)
                            )
                            .foregroundStyle(Brand.inkGradient)
                            .cornerRadius(4)
                        }
                        .frame(height: CGFloat(max(120, min(6, insights.topDistortions.count) * 36)))
                        if let top = insights.topDistortions.first {
                            Text("Your most common trap is \(top.distortion.name.lowercased()). Knowing your signature trap is half the catch.")
                                .font(.caption)
                                .foregroundStyle(Brand.text2)
                        }
                    }
                }
                .glassCard()
                .accessibilityLabel("Bar chart of your most common thinking traps")

                if insights.avgIntensityDrop > 0 {
                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow(text: "Does this actually work?")
                        Text("On average, your feelings drop \(Int(insights.avgIntensityDrop.rounded())) points (of 100) within a single record — your own data, not a promise.")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text)
                    }
                    .glassCard()
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(16)
        }
    }

    private func bigStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Brand.mono(18, weight: .semibold))
                .foregroundStyle(Brand.text)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 12)
        .accessibilityElement(children: .combine)
    }
}
