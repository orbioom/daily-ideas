import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query private var readings: [Reading]

    private var stats: ArcanaEngine.Stats { ArcanaEngine.stats(for: readings) }

    var body: some View {
        ScrollView {
            if !stats.hasData {
                EmptyStateView(icon: "chart.bar",
                               title: "No insights yet",
                               message: "Save a few readings and your patterns will appear here.")
                    .padding(.top, 60)
            } else {
                VStack(alignment: .leading, spacing: 22) {
                    statTiles
                    monthChart
                    suitChart
                    uprightSection
                    topCardsSection
                }
                .padding(20)
            }
        }
        .background(Brand.pageBackground)
        .navigationTitle("Insights")
    }

    private var statTiles: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(stats.totalReadings)", label: "Readings", tint: Brand.text)
            StatTile(value: "\(stats.currentStreak)", label: "Day streak", tint: Brand.magic)
            StatTile(value: "\(stats.majorSharePercent)%", label: "Major arcana", tint: Brand.info)
        }
    }

    private var monthChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "Readings per month")
                Chart(stats.perMonth) { point in
                    BarMark(
                        x: .value("Month", point.label),
                        y: .value("Readings", point.count)
                    )
                    .foregroundStyle(Brand.magic.gradient)
                    .cornerRadius(6)
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .accessibilityLabel("Readings per month bar chart")
                .accessibilityValue(stats.perMonth.map { "\($0.label): \($0.count)" }.joined(separator: ", "))
            }
        }
    }

    @ViewBuilder
    private var suitChart: some View {
        let slices = stats.suitDistribution.filter { $0.count > 0 }
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "Suit distribution")
                if slices.isEmpty {
                    Text("Only Major Arcana drawn so far.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text3)
                } else {
                    Chart(slices) { slice in
                        SectorMark(
                            angle: .value("Count", slice.count),
                            innerRadius: .ratio(0.58),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Suit", slice.suit.title))
                        .cornerRadius(4)
                    }
                    .frame(height: 200)
                    .chartLegend(position: .bottom, spacing: 12)
                    .accessibilityLabel("Suit distribution donut chart")
                    .accessibilityValue(slices.map { "\($0.suit.title): \($0.count)" }.joined(separator: ", "))
                }
            }
        }
    }

    private var uprightSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "Upright vs reversed")
                RankBar(title: "Upright",
                        detail: "\(stats.uprightCount) · \(stats.uprightPercent)%",
                        fraction: Double(stats.uprightPercent) / 100.0,
                        tint: Brand.magic)
                RankBar(title: "Reversed",
                        detail: "\(stats.reversedCount) · \(stats.reversedPercent)%",
                        fraction: Double(stats.reversedPercent) / 100.0,
                        tint: Brand.warn)
            }
        }
    }

    @ViewBuilder
    private var topCardsSection: some View {
        let top = Array(stats.topCards.prefix(6))
        let maxCount = max(1, top.first?.count ?? 1)
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "Most-drawn cards")
                if top.isEmpty {
                    Text("No cards drawn yet.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text3)
                } else {
                    ForEach(top) { rank in
                        RankBar(title: rank.card.name,
                                detail: "\(rank.count)×",
                                fraction: Double(rank.count) / Double(maxCount),
                                tint: Brand.info)
                    }
                }
            }
        }
    }
}
