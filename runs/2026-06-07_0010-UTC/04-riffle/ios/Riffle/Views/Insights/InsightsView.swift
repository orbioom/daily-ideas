import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query private var patterns: [Pattern]
    @Query private var catches: [Catch]
    @AppStorage("useMetric") private var useMetric = false

    private var confidence: (Pattern, Int)? {
        RiffleLogic.confidenceFly(patterns: patterns, catches: catches)
    }
    private var species: [(String, Int)] { RiffleLogic.bySpecies(catches) }

    private struct MonthBar: Identifiable {
        let month: Int; let count: Int
        var id: Int { month }
        var label: String { Fmt.shortMonth(month) }
    }
    private var monthBars: [MonthBar] {
        let by = RiffleLogic.catchesByMonth(catches)
        return (1...12).map { MonthBar(month: $0, count: by[$0] ?? 0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    if catches.isEmpty {
                        EmptyStateView(icon: "chart.bar.xaxis",
                                       title: "No insights yet",
                                       message: "Log a few catches and Riffle finds your confidence fly and the conditions that fish.")
                            .padding(.top, 50)
                    } else {
                        VStack(spacing: 18) {
                            statGrid
                            if let c = confidence { confidenceCard(c.0, c.1) }
                            monthChart
                            speciesCard
                        }
                        .padding(.horizontal, 18).padding(.vertical, 14)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var statGrid: some View {
        let released = catches.filter(\.released).count
        let rate = catches.isEmpty ? 0 : Double(released) / Double(catches.count) * 100
        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatTile(value: "\(catches.count)", label: "Catches")
                StatTile(value: RiffleLogic.averageWaterTemp(catches).map {
                    Units.temp($0, metric: useMetric) } ?? "—", label: "Avg water", accent: Brand.info)
            }
            HStack(spacing: 12) {
                StatTile(value: String(format: "%.0f%%", rate), label: "Released", accent: Brand.live)
                StatTile(value: "\(species.count)", label: "Species")
            }
        }
    }

    private func confidenceCard(_ p: Pattern, _ count: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "Confidence fly")
            HStack {
                Image(systemName: p.type.symbol).font(.title2).foregroundStyle(p.type.tint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(p.name).font(.title3.weight(.bold)).foregroundStyle(Brand.text)
                    Text("\(count) catch\(count == 1 ? "" : "es") · \(p.sizeLabel)")
                        .font(.caption).foregroundStyle(Brand.text3)
                }
                Spacer()
                StatusDot(color: Brand.live)
            }
        }
        .glassCard(padding: 18)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Confidence fly \(p.name), \(count) catches")
    }

    private var monthChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Catches by month")
            Chart(monthBars) { bar in
                BarMark(x: .value("Month", bar.label), y: .value("Catches", bar.count))
                    .foregroundStyle(Brand.info).cornerRadius(3)
            }
            .chartYAxis { AxisMarks(values: .automatic(desiredCount: 3)) }
            .frame(height: 170)
            .accessibilityLabel("Catches logged in each month")
        }
        .glassCard()
    }

    private var speciesCard: some View {
        let maxCount = species.map(\.1).max() ?? 1
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "By species")
            ForEach(species, id: \.0) { name, count in
                HStack(spacing: 12) {
                    Text(name).font(.subheadline).foregroundStyle(Brand.text)
                        .frame(width: 120, alignment: .leading).lineLimit(1)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Brand.hairline)
                            Capsule().fill(Brand.info)
                                .frame(width: max(4, geo.size.width * CGFloat(count) / CGFloat(maxCount)))
                        }
                    }
                    .frame(height: 8)
                    Text("\(count)").font(Brand.mono(13)).foregroundStyle(Brand.text2)
                        .frame(width: 28, alignment: .trailing)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(name): \(count) catches")
            }
        }
        .glassCard()
    }
}
