import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \ReviewSession.date, order: .reverse) private var sessions: [ReviewSession]
    @Query private var decks: [Deck]
    @AppStorage("dailyGoal") private var dailyGoal = 20
    @State private var stats: GlossaStats?

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if let stats {
                    if stats.totalReviews == 0 && stats.cardTotal == 0 {
                        EmptyStateView(
                            icon: "chart.bar.xaxis",
                            title: "No progress yet",
                            message: "Study your first deck and Glossa starts tracking streaks, accuracy, and mastery."
                        )
                    } else {
                        content(stats)
                    }
                } else {
                    ProgressView("Counting your words…")
                        .tint(Brand.text2)
                        .foregroundStyle(Brand.text2)
                }
            }
            .navigationTitle("Progress")
            .task(id: "\(sessions.count)-\(decks.count)") {
                stats = StatsEngine.compute(sessions: sessions, decks: decks)
            }
        }
    }

    private func content(_ stats: GlossaStats) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    bigStat("\(stats.streak)", stats.streak == 1 ? "day streak" : "day streak")
                    bigStat("\(stats.masteredTotal)", "mastered")
                    bigStat("\(Int((stats.accuracy * 100).rounded()))%", "accuracy")
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Eyebrow(text: "Reviews · last 14 days")
                        Spacer()
                        if todayCount(stats) >= dailyGoal {
                            HStack(spacing: 5) {
                                StatusDot()
                                Text("goal met")
                                    .font(.caption)
                                    .foregroundStyle(Brand.live)
                            }
                        }
                    }
                    Chart {
                        ForEach(stats.reviewsPerDay) { d in
                            BarMark(
                                x: .value("Day", d.day, unit: .day),
                                y: .value("Reviews", d.count)
                            )
                            .foregroundStyle(d.count >= dailyGoal ? Brand.live.gradient : Brand.text3.gradient)
                            .cornerRadius(3)
                        }
                        RuleMark(y: .value("Goal", dailyGoal))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundStyle(Brand.text3)
                    }
                    .frame(height: 150)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.day(), centered: true)
                        }
                    }
                    Text("Green days hit your goal of \(dailyGoal) reviews.")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
                .glassCard()
                .accessibilityLabel("Bar chart of reviews per day for the last two weeks")

                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "All cards by box")
                    Chart(Array(stats.boxDistribution.enumerated()), id: \.offset) { item in
                        BarMark(
                            x: .value("Box", "Box \(item.offset + 1)"),
                            y: .value("Cards", item.element)
                        )
                        .foregroundStyle(item.offset == LeitnerEngine.boxCount - 1
                                         ? Brand.live.gradient
                                         : Brand.text3.gradient)
                        .cornerRadius(3)
                    }
                    .frame(height: 140)
                    Text("The long game: move everything to box 5.")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
                .glassCard()
                .accessibilityLabel("Bar chart of cards per Leitner box")

                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "Recent sessions")
                    if sessions.isEmpty {
                        Text("No sessions yet.")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text3)
                    } else {
                        ForEach(sessions.prefix(6)) { s in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(s.deckName)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Brand.text)
                                    Text(s.date, format: .dateTime.weekday(.abbreviated).day().month().hour().minute())
                                        .font(.caption)
                                        .foregroundStyle(Brand.text3)
                                }
                                Spacer()
                                Text("\(s.correct)✓ \(s.missed)✕")
                                    .font(Brand.mono(13, weight: .medium))
                                    .foregroundStyle(Brand.text2)
                            }
                            .padding(.vertical, 3)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(s.deckName), \(s.correct) correct, \(s.missed) missed")
                        }
                    }
                }
                .glassCard()
            }
            .padding(16)
        }
    }

    private func todayCount(_ stats: GlossaStats) -> Int {
        stats.reviewsPerDay.last?.count ?? 0
    }

    private func bigStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Brand.mono(20, weight: .semibold))
                .foregroundStyle(Brand.text)
            Text(label)
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 12)
        .accessibilityElement(children: .combine)
    }
}
