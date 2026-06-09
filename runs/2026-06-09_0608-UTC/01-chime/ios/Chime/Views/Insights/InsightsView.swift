import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \MeditationSession.date, order: .reverse) private var sessions: [MeditationSession]
    @State private var range = 14

    private var summary: StatsEngine.Summary { StatsEngine.summary(sessions) }
    private var series: [StatsEngine.DailyPoint] { StatsEngine.dailySeries(sessions, days: range) }
    private var byPreset: [(name: String, minutes: Int)] { StatsEngine.minutesByPreset(sessions) }

    var body: some View {
        NavigationStack {
            ScrollView {
                if sessions.isEmpty {
                    EmptyStateView(icon: "chart.xyaxis.line",
                                   title: "Nothing to show yet",
                                   message: "Finish a sit and your minutes, streaks, and steadiness will appear here.")
                        .glassCard()
                        .padding(20)
                } else {
                    VStack(spacing: 18) {
                        statsGrid
                        minutesChart
                        if byPreset.count > 1 { presetBreakdown }
                    }
                    .padding(20)
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("Insights")
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(value: "\(summary.currentStreak)", label: "Day streak", tint: Brand.magic)
            StatTile(value: "\(summary.longestStreak)", label: "Best streak")
            StatTile(value: Format.duration(summary.totalMinutes * 60), label: "Total time")
            StatTile(value: "\(Int((summary.completionRate * 100).rounded()))%", label: "Completed")
        }
    }

    private var minutesChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "Minutes per day")
                Spacer()
                Picker("Range", selection: $range) {
                    Text("14d").tag(14)
                    Text("30d").tag(30)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }
            Chart(series) { point in
                BarMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value("Minutes", point.minutes)
                )
                .foregroundStyle(Brand.magic.gradient)
                .cornerRadius(4)
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(); AxisValueLabel()
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: range > 14 ? 7 : 3)) { value in
                    AxisValueLabel(format: .dateTime.day().month(.narrow))
                }
            }
            .accessibilityLabel("Bar chart of meditation minutes per day")
        }
        .glassCard()
    }

    private var presetBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Where your minutes go")
            ForEach(Array(byPreset.prefix(6).enumerated()), id: \.offset) { _, item in
                let total = max(1, byPreset.reduce(0) { $0 + $1.minutes })
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.name).font(.subheadline).foregroundStyle(Brand.text)
                        Spacer()
                        Text("\(item.minutes) min").font(Brand.mono(13)).foregroundStyle(Brand.text2)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Brand.hairline)
                            Capsule().fill(Brand.magic.opacity(0.8))
                                .frame(width: geo.size.width * CGFloat(item.minutes) / CGFloat(total))
                        }
                    }
                    .frame(height: 8)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(item.name): \(item.minutes) minutes")
            }
        }
        .glassCard()
    }
}
