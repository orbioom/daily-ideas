import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \DrinkLog.date, order: .reverse) private var allLogs: [DrinkLog]
    @AppStorage("volumeUnit") private var unitRaw = VolumeUnit.ml.rawValue

    private let engine = HydrationEngine()
    private var unit: VolumeUnit { VolumeUnit(rawValue: unitRaw) ?? .ml }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if allLogs.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar",
                        title: "No insights yet",
                        message: "Once you've logged some drinks, you'll see your sources, best days, and weekly rhythm here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            statTiles
                            sourcesCard
                            weekdayCard
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var sources: [HydrationEngine.SourceTotal] { engine.sources(allLogs) }
    private var weekdays: [HydrationEngine.WeekdayAverage] { engine.weekdayAverages(allLogs) }

    private var statTiles: some View {
        let allTime = engine.rawTotal(allLogs)
        let caffeine = engine.caffeineTotal(allLogs)
        let bestDay = engine.dailyTotals(allLogs, days: 90, goalML: 0).max { $0.effectiveML < $1.effectiveML }
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            tile(Units.headline(allTime, as: unit), "all-time intake", "drop.fill")
            tile("\(allLogs.count)", "drinks logged", "list.bullet")
            tile(Units.string(bestDay?.effectiveML ?? 0, as: unit), "best day", "trophy.fill")
            tile("\(Int(caffeine)) mg", "total caffeine", "bolt.fill")
        }
    }

    private func tile(_ value: String, _ label: String, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol).font(.title3).foregroundStyle(Color.accentColor)
            Text(value).font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Brand.text).minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.caption).foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    private var sourcesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Where it comes from").font(.headline).foregroundStyle(Brand.text)
            Chart(sources) { s in
                SectorMark(angle: .value("Volume", s.volumeML), innerRadius: .ratio(0.6), angularInset: 1.5)
                    .foregroundStyle(Color(hex: s.colorHex))
                    .cornerRadius(3)
            }
            .frame(height: 170)
            ForEach(sources.prefix(6)) { s in
                HStack(spacing: 8) {
                    Circle().fill(Color(hex: s.colorHex)).frame(width: 9, height: 9)
                    Text(s.name).font(.subheadline).foregroundStyle(Brand.text2)
                    Spacer()
                    Text(Units.string(s.volumeML, as: unit))
                        .font(Brand.mono(12, weight: .medium)).foregroundStyle(Brand.text)
                }
            }
        }
        .glassCard()
    }

    private var weekdayCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your weekly rhythm").font(.headline).foregroundStyle(Brand.text)
            Chart(weekdays) { w in
                BarMark(
                    x: .value("Day", w.symbol),
                    y: .value("Avg", Units.display(w.averageML, as: unit))
                )
                .foregroundStyle(Color.accentColor.gradient)
                .cornerRadius(5)
            }
            .chartXScale(domain: weekdays.map { $0.symbol })
            .frame(height: 160)
        }
        .glassCard()
    }
}
