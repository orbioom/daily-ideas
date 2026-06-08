import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \BreathSession.date, order: .reverse) private var sessions: [BreathSession]
    private var stats: SessionStats { SessionStats.make(from: sessions) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if sessions.isEmpty {
                    EmptyStateView(icon: "chart.bar", title: "No insights yet",
                                   message: "Finish a few sessions to see your minutes and streak.")
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            statsCard
                            chartCard
                            if let fav = stats.favoritePattern {
                                GlassCard {
                                    HStack {
                                        Image(systemName: "heart.fill").foregroundStyle(Brand.magic)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Eyebrow(text: "MOST PRACTISED")
                                            Text(fav).font(.headline).foregroundStyle(Brand.text)
                                        }
                                        Spacer()
                                    }
                                    .accessibilityElement(children: .combine)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var statsCard: some View {
        GlassCard {
            HStack(spacing: 12) {
                StatTile(value: "\(Int(stats.totalMinutes))", label: "Total min", tint: Brand.magic)
                Divider().frame(height: 40).overlay(Brand.hairline)
                StatTile(value: "\(stats.streakDays)", label: "Day streak")
                Divider().frame(height: 40).overlay(Brand.hairline)
                StatTile(value: "\(stats.sessionCount)", label: "Sessions")
            }
        }
    }

    private var chartCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "LAST 14 DAYS")
                Chart(stats.last14) { bar in
                    BarMark(x: .value("Day", bar.date, unit: .day),
                            y: .value("Minutes", bar.minutes))
                        .foregroundStyle(Brand.magic.gradient)
                        .cornerRadius(5)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { v in
                        AxisGridLine().foregroundStyle(Brand.hairline)
                        AxisValueLabel { if let m = v.as(Double.self) { Text("\(Int(m))m") } }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                        AxisValueLabel(format: .dateTime.day(), centered: false)
                    }
                }
                .frame(height: 180)
            }
        }
    }
}
