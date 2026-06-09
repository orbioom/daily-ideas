import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \Attack.start, order: .reverse) private var attacks: [Attack]
    @AppStorage("aura.overuseThreshold") private var overuseThreshold = 10
    @AppStorage("aura.showImpact") private var showImpact = true

    private var monthly: [AuraEngine.MonthPoint] { AuraEngine.monthlySeries(attacks, months: 6) }
    private var intensityPoints: [AuraEngine.IntensityPoint] { AuraEngine.intensitySeries(attacks, days: 90) }
    private var triggerRanks: [AuraEngine.TriggerRank] { AuraEngine.triggerCorrelation(attacks) }
    private var symptomRanks: [AuraEngine.SymptomRank] { AuraEngine.symptomFrequency(attacks) }
    private var medEffects: [AuraEngine.MedEffect] { AuraEngine.medicationEffectiveness(attacks) }
    private var impact: AuraEngine.Impact { AuraEngine.impact(attacks) }

    var body: some View {
        NavigationStack {
            ScrollView {
                if attacks.isEmpty {
                    EmptyStateView(icon: "chart.xyaxis.line",
                                   title: "Nothing to chart yet",
                                   message: "Log a few attacks and your frequency, intensity, triggers, and impact will appear here.")
                        .glassCard()
                        .padding(20)
                } else {
                    VStack(spacing: 18) {
                        statsGrid
                        frequencyChart
                        intensityChart
                        if !triggerRanks.isEmpty { triggerRanking }
                        if !symptomRanks.isEmpty { symptomChart }
                        if !medEffects.isEmpty { medCard }
                        if showImpact { impactCard }
                    }
                    .padding(20)
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("Insights")
        }
    }

    // MARK: Stats

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(value: "\(AuraEngine.attacksThisMonth(attacks))", label: "This month", tint: Brand.magic)
            StatTile(value: String(format: "%.1f", AuraEngine.avgIntensity(attacks)), label: "Avg intensity")
            if let avg = AuraEngine.avgDurationMinutes(attacks) {
                StatTile(value: Format.duration(minutes: Int(avg.rounded())), label: "Avg duration")
            } else {
                StatTile(value: "—", label: "Avg duration")
            }
            StatTile(value: AuraEngine.mostCommonType(attacks)?.label ?? "—", label: "Most common")
        }
    }

    // MARK: Charts

    private var frequencyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Attacks per month")
            Chart(monthly) { point in
                BarMark(
                    x: .value("Month", point.month, unit: .month),
                    y: .value("Attacks", point.count)
                )
                .foregroundStyle(Brand.magic.gradient)
                .cornerRadius(4)
            }
            .frame(height: 180)
            .chartYAxis { AxisMarks(position: .leading) { _ in AxisGridLine(); AxisValueLabel() } }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.narrow))
                }
            }
            .accessibilityLabel("Bar chart of attacks per month over the last six months")
        }
        .glassCard()
    }

    private var intensityChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Intensity over time")
            Chart(intensityPoints) { point in
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Intensity", point.intensity)
                )
                .foregroundStyle(Brand.info)
                .interpolationMethod(.catmullRom)
                PointMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Intensity", point.intensity)
                )
                .foregroundStyle(IntensityScale.color(point.intensity))
                .symbolSize(40)
            }
            .frame(height: 180)
            .chartYScale(domain: 0...10)
            .chartYAxis { AxisMarks(position: .leading, values: [0, 2, 4, 6, 8, 10]) { _ in AxisGridLine(); AxisValueLabel() } }
            .accessibilityLabel("Line chart of attack intensity over the last 90 days")
        }
        .glassCard()
    }

    private var triggerRanking: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Likely triggers")
            Text("Share of attacks where each trigger was present.")
                .font(.footnote).foregroundStyle(Brand.text3)
            ForEach(triggerRanks.prefix(8)) { rank in
                RankBar(title: rank.name,
                        detail: "\(Int((rank.fraction * 100).rounded()))% · \(rank.presentCount)",
                        fraction: rank.fraction,
                        tint: Brand.warn)
            }
        }
        .glassCard()
    }

    private var symptomChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Symptom frequency")
            Chart(symptomRanks.prefix(8)) { rank in
                BarMark(
                    x: .value("Count", rank.count),
                    y: .value("Symptom", rank.name)
                )
                .foregroundStyle(Brand.magic.gradient)
                .cornerRadius(4)
            }
            .frame(height: CGFloat(max(1, min(symptomRanks.count, 8)) * 34 + 20))
            .chartXAxis { AxisMarks { _ in AxisGridLine(); AxisValueLabel() } }
            .accessibilityLabel("Bar chart of symptom frequency")
        }
        .glassCard()
    }

    private var medCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Medication & relief")
            Text("Average relief on a 0–3 scale, with times taken.")
                .font(.footnote).foregroundStyle(Brand.text3)
            ForEach(medEffects.prefix(8)) { med in
                RankBar(title: "\(med.name)  ·  \(med.timesTaken)×",
                        detail: String(format: "%.1f / 3", med.avgRelief),
                        fraction: med.avgRelief / 3.0,
                        tint: Brand.live)
            }
        }
        .glassCard()
    }

    private var impactCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Impact · last 30 days")
            HStack(spacing: 12) {
                StatTile(value: "\(impact.headacheDays)", label: "Headache days", tint: Brand.danger)
                StatTile(value: Format.hours(impact.hoursAffected), label: "Hours affected")
            }
            Text("A rough MIDAS-style snapshot of how much headaches affected the past month.")
                .font(.footnote).foregroundStyle(Brand.text3)
        }
        .glassCard()
    }
}
