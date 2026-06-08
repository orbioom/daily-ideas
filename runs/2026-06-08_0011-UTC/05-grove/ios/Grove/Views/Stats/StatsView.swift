import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \FocusSession.date, order: .reverse) private var sessions: [FocusSession]
    @Query(sort: \FocusTag.order) private var tags: [FocusTag]
    private var stats: FocusStats { FocusStats.make(from: sessions) }

    private func color(for name: String) -> Color {
        tags.first { $0.name == name }.map { Color(hex: $0.colorHex) } ?? Brand.live
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if sessions.isEmpty {
                    EmptyStateView(icon: "chart.bar", title: "No stats yet",
                                   message: "Complete focus sessions to see your minutes and patterns.")
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            summary
                            dailyChart
                            tagChart
                            successCard
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }

    private var summary: some View {
        GlassCard {
            HStack {
                StatTile(value: Format.minutes(stats.todayMinutes), label: "Today", tint: Brand.live)
                Divider().frame(height: 36).overlay(Brand.hairline)
                StatTile(value: Format.minutes(stats.totalMinutes), label: "All time")
                Divider().frame(height: 36).overlay(Brand.hairline)
                StatTile(value: "\(stats.treesPlanted)", label: "Trees")
            }
        }
    }

    private var dailyChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "FOCUS · LAST 14 DAYS")
                Chart(stats.last14) { bar in
                    BarMark(x: .value("Day", bar.date, unit: .day),
                            y: .value("Minutes", bar.minutes))
                        .foregroundStyle(Brand.live.gradient).cornerRadius(5)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { v in
                        AxisGridLine().foregroundStyle(Brand.hairline)
                        AxisValueLabel { if let m = v.as(Double.self) { Text("\(Int(m))m") } }
                    }
                }
                .chartXAxis { AxisMarks(values: .stride(by: .day, count: 2)) { _ in AxisValueLabel(format: .dateTime.day()) } }
                .frame(height: 180)
            }
        }
    }

    private var tagChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "WHERE FOCUS GOES")
                if stats.byTag.isEmpty {
                    Text("No tagged sessions yet.").font(.subheadline).foregroundStyle(Brand.text2)
                } else {
                    Chart(stats.byTag) { slice in
                        BarMark(x: .value("Minutes", slice.minutes),
                                y: .value("Tag", slice.name))
                            .foregroundStyle(color(for: slice.name))
                            .cornerRadius(5)
                            .annotation(position: .trailing) {
                                Text(Format.minutes(slice.minutes)).font(.caption2).foregroundStyle(Brand.text3)
                            }
                    }
                    .chartXAxis { AxisMarks { AxisGridLine().foregroundStyle(Brand.hairline) } }
                    .frame(height: CGFloat(stats.byTag.count * 44 + 20))
                }
            }
        }
    }

    private var successCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "FOCUS SUCCESS")
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(stats.successRate * 100))%")
                        .font(Brand.mono(30, weight: .semibold)).foregroundStyle(Brand.text)
                    Text("of sessions completed")
                        .font(.subheadline).foregroundStyle(Brand.text2)
                }
                ProgressView(value: stats.successRate).tint(Brand.live)
                Text("\(stats.treesPlanted) planted · \(stats.withered) withered")
                    .font(.footnote).foregroundStyle(Brand.text3)
            }
        }
    }
}
