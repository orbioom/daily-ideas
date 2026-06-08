import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \MoodEntry.date, order: .reverse) private var entries: [MoodEntry]
    @Query(sort: \Activity.order) private var activities: [Activity]
    @AppStorage("tide.trendDays") private var trendDays = 30

    private var insights: MoodInsights {
        MoodInsights.make(entries: entries, activities: activities, days: trendDays)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if entries.count < 2 {
                    EmptyStateView(icon: "chart.xyaxis.line",
                                   title: "Not enough yet",
                                   message: "Log a few check-ins and Tide will surface your trend and what affects your mood.")
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            headline
                            trendChart
                            correlationCard
                            distributionCard
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var headline: some View {
        GlassCard {
            HStack(spacing: 16) {
                StatTile(value: String(format: "%.1f", insights.average), label: "Avg mood", tint: Mood.color(Int(insights.average.rounded())))
                Divider().frame(height: 40).overlay(Brand.hairline)
                StatTile(value: "\(insights.streakDays)", label: "Day streak")
                Divider().frame(height: 40).overlay(Brand.hairline)
                StatTile(value: "\(insights.entryCount)", label: "Check-ins")
            }
        }
    }

    private var trendChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Eyebrow(text: "MOOD TREND")
                    Spacer()
                    Picker("Window", selection: $trendDays) {
                        Text("14d").tag(14); Text("30d").tag(30); Text("90d").tag(90)
                    }
                    .pickerStyle(.segmented).frame(width: 160)
                }
                Chart(insights.trend.filter { $0.count > 0 }) { point in
                    LineMark(x: .value("Day", point.date), y: .value("Mood", point.average))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Brand.info)
                    AreaMark(x: .value("Day", point.date), y: .value("Mood", point.average))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(LinearGradient(colors: [Brand.info.opacity(0.25), .clear], startPoint: .top, endPoint: .bottom))
                    PointMark(x: .value("Day", point.date), y: .value("Mood", point.average))
                        .foregroundStyle(Mood.color(Int(point.average.rounded())))
                        .symbolSize(40)
                }
                .chartYScale(domain: 1...5)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [1, 2, 3, 4, 5]) { v in
                        AxisGridLine().foregroundStyle(Brand.hairline)
                        AxisValueLabel { if let i = v.as(Int.self) { Text(Mood.label(i)).font(.caption2) } }
                    }
                }
                .frame(height: 200)
            }
        }
    }

    private var correlationCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Eyebrow(text: "WHAT MOVES YOUR MOOD")
                if insights.correlations.isEmpty {
                    Text("Tag activities on your check-ins to reveal correlations.")
                        .font(.subheadline).foregroundStyle(Brand.text2)
                } else {
                    ForEach(insights.correlations.prefix(6)) { impact in
                        HStack(spacing: 12) {
                            Image(systemName: impact.symbol)
                                .frame(width: 24)
                                .foregroundStyle(Brand.text2)
                            Text(impact.name).font(.subheadline).foregroundStyle(Brand.text)
                            Spacer()
                            Text("\(impact.sampleSize)×").font(Brand.mono(11)).foregroundStyle(Brand.text3)
                            Text(Format.signed(impact.delta))
                                .font(Brand.mono(14, weight: .semibold))
                                .foregroundStyle(impact.delta >= 0 ? Brand.live : Brand.danger)
                                .frame(width: 56, alignment: .trailing)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(impact.name): \(impact.delta >= 0 ? "lifts" : "lowers") mood by \(String(format: "%.2f", abs(impact.delta))), \(impact.sampleSize) entries")
                    }
                    Text("Difference from your overall average mood when each activity is present.")
                        .font(.caption).foregroundStyle(Brand.text3)
                }
            }
        }
    }

    private var distributionCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "MOOD MIX")
                Chart {
                    ForEach(1...5, id: \.self) { level in
                        BarMark(
                            x: .value("Count", insights.distribution[level] ?? 0),
                            y: .value("Mood", Mood.label(level))
                        )
                        .foregroundStyle(Mood.color(level))
                        .cornerRadius(5)
                    }
                }
                .chartXAxis {
                    AxisMarks { AxisGridLine().foregroundStyle(Brand.hairline); AxisValueLabel() }
                }
                .frame(height: 170)
            }
        }
    }
}
