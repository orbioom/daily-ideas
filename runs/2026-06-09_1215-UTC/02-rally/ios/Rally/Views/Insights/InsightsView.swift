import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query private var players: [Player]
    @Query private var matches: [Match]

    private var completed: [Match] { matches.filter { $0.isComplete } }
    private var me: Player? { players.first { $0.isMe } }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let me, !completed.isEmpty,
                   StatsEngine.record(for: me, in: completed).total > 0 {
                    content(for: me)
                } else {
                    EmptyStateView(icon: "chart.xyaxis.line",
                                   title: "No insights yet",
                                   message: "Finish a match and your rating trend, win rates, and streaks will appear here.")
                        .glassCard()
                        .padding(20)
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("Insights")
        }
    }

    private func content(for me: Player) -> some View {
        let record = StatsEngine.record(for: me, in: completed)
        let streak = StatsEngine.currentStreak(for: me, in: completed)
        let points = StatsEngine.pointsFor(me, in: completed)
        return VStack(spacing: 18) {
            statsGrid(record: record, streak: streak)
            ratingChart(for: me)
            winRateBySport(for: me)
            matchesPerMonthChart(for: me)
            outcomeDonut(record: record)
            pointsCard(points: points)
        }
        .padding(20)
    }

    private func statsGrid(record: StatsEngine.Record, streak: Int) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(value: record.line, label: "Record")
            StatTile(value: "\(record.winRatePercent)%", label: "Win rate", tint: Brand.live)
            StatTile(value: StatsEngine.streakLabel(streak),
                     label: "Current streak", tint: streak >= 0 ? Brand.live : Brand.danger)
            StatTile(value: "\(record.total)", label: "Matches")
        }
    }

    private func ratingChart(for me: Player) -> some View {
        let series = StatsEngine.ratingHistory(for: me, in: completed)
        return VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Rating over time")
            Chart(series) { point in
                LineMark(
                    x: .value("Match", point.index),
                    y: .value("Rating", point.rating)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(Brand.magic)
                AreaMark(
                    x: .value("Match", point.index),
                    y: .value("Rating", point.rating)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(Brand.magic.opacity(0.12))
            }
            .chartYScale(domain: ratingDomain(series))
            .frame(height: 180)
            .chartXAxis(.hidden)
            .accessibilityLabel("Line chart of your rating over \(series.count) points, currently \(Format.rating(me.rating))")
        }
        .glassCard()
    }

    private func ratingDomain(_ series: [StatsEngine.RatingPoint]) -> ClosedRange<Double> {
        let values = series.map(\.rating)
        let lo = (values.min() ?? 3.0) - 0.15
        let hi = (values.max() ?? 3.0) + 0.15
        return max(2.0, lo)...min(6.0, hi)
    }

    private func winRateBySport(for me: Player) -> some View {
        let data: [(sport: Sport, rate: Double, total: Int)] = Sport.allCases.map {
            let r = StatsEngine.record(for: me, sport: $0, in: completed)
            return ($0, r.winRate, r.total)
        }.filter { $0.total > 0 }
        return VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Win rate by sport")
            Chart(data, id: \.sport) { item in
                BarMark(
                    x: .value("Sport", item.sport.label),
                    y: .value("Win rate", item.rate)
                )
                .foregroundStyle(item.sport.tint.gradient)
                .cornerRadius(6)
                .annotation(position: .top) {
                    Text("\(Int((item.rate * 100).rounded()))%")
                        .font(Brand.mono(11)).foregroundStyle(Brand.text2)
                }
            }
            .chartYScale(domain: 0...1)
            .frame(height: 160)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 0.5, 1.0]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let d = value.as(Double.self) {
                            Text("\(Int(d * 100))%")
                        }
                    }
                }
            }
            .accessibilityLabel("Bar chart of win rate by sport")
        }
        .glassCard()
    }

    private func matchesPerMonthChart(for me: Player) -> some View {
        let series = StatsEngine.matchesPerMonth(for: me, in: completed, months: 6)
        return VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Matches per month")
            Chart(series) { point in
                BarMark(
                    x: .value("Month", point.date, unit: .month),
                    y: .value("Matches", point.count)
                )
                .foregroundStyle(Brand.info.gradient)
                .cornerRadius(4)
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisValueLabel(format: .dateTime.month(.narrow))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in AxisGridLine(); AxisValueLabel() }
            }
            .accessibilityLabel("Bar chart of matches played per month")
        }
        .glassCard()
    }

    private func outcomeDonut(record: StatsEngine.Record) -> some View {
        let data = [
            (label: "Wins", value: record.wins, color: Brand.live),
            (label: "Losses", value: record.losses, color: Brand.danger)
        ]
        return VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Wins & losses")
            HStack(spacing: 20) {
                Chart(data, id: \.label) { item in
                    SectorMark(
                        angle: .value("Count", item.value),
                        innerRadius: .ratio(0.62),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(4)
                }
                .frame(width: 130, height: 130)
                .accessibilityLabel("Donut chart: \(record.wins) wins, \(record.losses) losses")

                VStack(alignment: .leading, spacing: 10) {
                    legendRow(color: Brand.live, label: "Wins", value: record.wins)
                    legendRow(color: Brand.danger, label: "Losses", value: record.losses)
                }
                Spacer()
            }
        }
        .glassCard()
    }

    private func legendRow(color: Color, label: String, value: Int) -> some View {
        HStack(spacing: 8) {
            StatusDot(color: color)
            Text(label).font(.subheadline).foregroundStyle(Brand.text2)
            Spacer()
            Text("\(value)").font(Brand.mono(16, weight: .semibold)).foregroundStyle(Brand.text)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private func pointsCard(points: (scored: Int, conceded: Int)) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Points")
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(points.scored)")
                        .font(Brand.mono(26, weight: .bold)).foregroundStyle(Brand.live)
                    Text("Scored").font(.caption).foregroundStyle(Brand.text3)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(points.conceded)")
                        .font(Brand.mono(26, weight: .bold)).foregroundStyle(Brand.danger)
                    Text("Conceded").font(.caption).foregroundStyle(Brand.text3)
                }
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Points scored \(points.scored), conceded \(points.conceded)")
    }
}
