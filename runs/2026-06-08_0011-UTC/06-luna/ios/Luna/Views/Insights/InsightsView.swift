import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \Period.startDate, order: .reverse) private var periods: [Period]
    @Query private var logs: [DayLog]
    @AppStorage("luna.defaultCycle") private var defaultCycle = 28
    @AppStorage("luna.defaultPeriod") private var defaultPeriod = 5

    private var predictor: CyclePredictor {
        CyclePredictor.make(periods: periods, defaultCycle: defaultCycle, defaultPeriod: defaultPeriod)
    }

    private struct CycleBar: Identifiable { let id = UUID(); let index: Int; let length: Int }
    private var cycleBars: [CycleBar] {
        predictor.cycleLengths.enumerated().map { CycleBar(index: $0.offset + 1, length: $0.element) }
    }

    private struct SymCount: Identifiable { let id = UUID(); let name: String; let count: Int }
    private var symptomCounts: [SymCount] {
        var dict: [String: Int] = [:]
        for log in logs { for s in log.symptoms { dict[s, default: 0] += 1 } }
        return dict.map { SymCount(name: $0.key, count: $0.value) }.sorted { $0.count > $1.count }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if periods.isEmpty {
                    EmptyStateView(icon: "chart.bar", title: "No insights yet",
                                   message: "Log a few cycles to see your cycle-length trend, regularity, and symptom patterns.")
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            regularityCard
                            if cycleBars.count >= 1 { cycleChart }
                            if !symptomCounts.isEmpty { symptomCard }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var regularityCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "CYCLE REGULARITY")
                HStack(spacing: 12) {
                    StatTile(value: "\(predictor.averageCycle)", label: "Avg cycle days", tint: LunaColors.luteal)
                    Divider().frame(height: 40).overlay(Brand.hairline)
                    StatTile(value: regText, label: "Variation")
                    Divider().frame(height: 40).overlay(Brand.hairline)
                    StatTile(value: "\(predictor.averagePeriod)", label: "Avg period days")
                }
                Text(regularityNote).font(.footnote).foregroundStyle(Brand.text3)
            }
        }
    }

    private var cycleChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "CYCLE LENGTH OVER TIME")
                Chart {
                    ForEach(cycleBars) { bar in
                        BarMark(x: .value("Cycle", bar.index),
                                y: .value("Days", bar.length))
                            .foregroundStyle(LunaColors.luteal.gradient)
                            .cornerRadius(5)
                    }
                    RuleMark(y: .value("Average", predictor.averageCycle))
                        .foregroundStyle(Brand.text3)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5,3]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("avg").font(.caption2).foregroundStyle(Brand.text3)
                        }
                }
                .chartYScale(domain: 20...40)
                .chartYAxis { AxisMarks(position: .leading) { AxisGridLine().foregroundStyle(Brand.hairline); AxisValueLabel() } }
                .chartXAxis { AxisMarks { AxisValueLabel() } }
                .frame(height: 190)
            }
        }
    }

    private var symptomCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "MOST LOGGED SYMPTOMS")
                Chart(symptomCounts.prefix(6).map { $0 }) { s in
                    BarMark(x: .value("Count", s.count), y: .value("Symptom", s.name))
                        .foregroundStyle(LunaColors.period.gradient)
                        .cornerRadius(5)
                        .annotation(position: .trailing) {
                            Text("\(s.count)").font(.caption2).foregroundStyle(Brand.text3)
                        }
                }
                .chartXAxis { AxisMarks { AxisGridLine().foregroundStyle(Brand.hairline) } }
                .frame(height: CGFloat(min(6, symptomCounts.count) * 40 + 20))
            }
        }
    }

    private var regText: String {
        guard let r = predictor.regularity else { return "—" }
        return "±\(String(format: "%.1f", r))d"
    }
    private var regularityNote: String {
        guard let r = predictor.regularity else { return "Log more cycles to assess regularity." }
        if r < 2 { return "Your cycles are very regular." }
        if r < 4 { return "Your cycles are fairly regular." }
        return "Your cycles vary a fair amount — predictions are rougher."
    }
}
