import SwiftUI
import SwiftData
import Charts

struct TrendsView: View {
    @Query(sort: \VitalEntry.date, order: .reverse) private var entries: [VitalEntry]

    @AppStorage("cuff.weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue
    @AppStorage("cuff.glucoseUnit") private var glucoseUnitRaw = GlucoseUnit.mgdl.rawValue
    @AppStorage("cuff.targetSystolic") private var targetSystolic = 120
    @AppStorage("cuff.targetDiastolic") private var targetDiastolic = 80

    @State private var range = 30

    private var weightUnit: WeightUnit { WeightUnit.from(weightUnitRaw) }
    private var glucoseUnit: GlucoseUnit { GlucoseUnit.from(glucoseUnitRaw) }

    private func windowed(_ kind: VitalKind) -> [VitalEntry] {
        VitalsEngine.within(VitalsEngine.entries(entries, kind: kind), days: range)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if entries.isEmpty {
                    EmptyStateView(icon: "chart.xyaxis.line",
                                   title: "No trends yet",
                                   message: "Log a few readings and your charts will fill in here.")
                        .glassCard()
                        .padding(20)
                } else {
                    VStack(spacing: 18) {
                        rangePicker
                        bpChartCard
                        categoryDistributionCard
                        valueChartCard(.weight)
                        valueChartCard(.glucose)
                        valueChartCard(.pulse)
                    }
                    .padding(20)
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("Trends")
        }
    }

    private var rangePicker: some View {
        Picker("Range", selection: $range) {
            Text("7 days").tag(7)
            Text("30 days").tag(30)
            Text("90 days").tag(90)
        }
        .pickerStyle(.segmented)
        .onChange(of: range) { _, _ in Haptics.selection() }
    }

    // MARK: - Blood pressure chart with AHA band + target line

    @ViewBuilder private var bpChartCard: some View {
        let bp = windowed(.bloodPressure)
        let series = VitalsEngine.bpSeries(bp)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "Blood pressure")
                Spacer()
                if let avg = VitalsEngine.bpAverage(bp) {
                    BPCategoryBadge(category: avg.category, compact: true)
                }
            }
            if series.isEmpty {
                EmptyStateView(icon: "heart", title: "No BP readings",
                               message: "No blood-pressure readings in this range.")
            } else {
                Chart {
                    // Stage-2 hypertension threshold band (≥140 systolic).
                    RectangleMark(yStart: .value("Lo", 140), yEnd: .value("Hi", 200))
                        .foregroundStyle(Brand.danger.opacity(0.08))
                    // Stage-1 band (130–139).
                    RectangleMark(yStart: .value("Lo", 130), yEnd: .value("Hi", 140))
                        .foregroundStyle(Brand.warn.opacity(0.08))

                    RuleMark(y: .value("Target systolic", targetSystolic))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(Brand.info.opacity(0.7))
                        .annotation(position: .top, alignment: .leading) {
                            Text("Target \(targetSystolic)").font(Brand.mono(9)).foregroundStyle(Brand.info)
                        }

                    ForEach(series) { p in
                        LineMark(x: .value("Date", p.date), y: .value("Systolic", p.systolic),
                                 series: .value("Series", "Systolic"))
                            .foregroundStyle(Brand.danger)
                            .interpolationMethod(.catmullRom)
                        LineMark(x: .value("Date", p.date), y: .value("Diastolic", p.diastolic),
                                 series: .value("Series", "Diastolic"))
                            .foregroundStyle(Brand.info)
                            .interpolationMethod(.catmullRom)
                        PointMark(x: .value("Date", p.date), y: .value("Systolic", p.systolic))
                            .foregroundStyle(Brand.danger).symbolSize(18)
                        PointMark(x: .value("Date", p.date), y: .value("Diastolic", p.diastolic))
                            .foregroundStyle(Brand.info).symbolSize(18)
                    }
                }
                .frame(height: 220)
                .chartYScale(domain: 40...190)
                .chartYAxis { AxisMarks(position: .leading) }
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
                .accessibilityLabel("Line chart of systolic and diastolic blood pressure over the last \(range) days")

                HStack(spacing: 16) {
                    legendDot(Brand.danger, "Systolic")
                    legendDot(Brand.info, "Diastolic")
                }
                .font(Brand.mono(11)).foregroundStyle(Brand.text2)
            }
        }
        .glassCard()
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }

    // MARK: - Category distribution

    @ViewBuilder private var categoryDistributionCard: some View {
        let bp = windowed(.bloodPressure)
        let dist = VitalsEngine.categoryDistribution(bp)
        let total = max(1, dist.reduce(0) { $0 + $1.count })
        if bp.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "Stage breakdown")
                Chart(dist, id: \.category) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Stage", item.category.label)
                    )
                    .foregroundStyle(item.category.color)
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        if item.count > 0 {
                            Text("\(Int((Double(item.count) / Double(total) * 100).rounded()))%")
                                .font(Brand.mono(10)).foregroundStyle(Brand.text3)
                        }
                    }
                }
                .frame(height: 160)
                .chartXAxis { AxisMarks() }
                .accessibilityLabel("Bar chart of blood-pressure stage distribution")
            }
            .glassCard()
        }
    }

    // MARK: - Generic value chart (weight / glucose / pulse)

    @ViewBuilder private func valueChartCard(_ kind: VitalKind) -> some View {
        let xs = windowed(kind)
        let series = VitalsEngine.valueSeries(xs)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: kind.label)
                Spacer()
                if let trend = VitalsEngine.valueTrend(VitalsEngine.entries(entries, kind: kind), days: range) {
                    TrendChip(trend: displayTrend(trend, kind: kind),
                              lowerIsBetter: kind == .weight || kind == .glucose)
                }
            }
            if series.isEmpty {
                EmptyStateView(icon: kind.symbol, title: "No \(kind.shortLabel.lowercased()) yet",
                               message: "No \(kind.label.lowercased()) readings in this range.")
            } else {
                Chart(series) { p in
                    AreaMark(x: .value("Date", p.date), y: .value("Value", displayValue(p.value, kind: kind)))
                        .foregroundStyle(kind.tint.opacity(0.15))
                        .interpolationMethod(.catmullRom)
                    LineMark(x: .value("Date", p.date), y: .value("Value", displayValue(p.value, kind: kind)))
                        .foregroundStyle(kind.tint)
                        .interpolationMethod(.catmullRom)
                    PointMark(x: .value("Date", p.date), y: .value("Value", displayValue(p.value, kind: kind)))
                        .foregroundStyle(kind.tint).symbolSize(18)
                }
                .frame(height: 160)
                .chartYAxis { AxisMarks(position: .leading) }
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
                .accessibilityLabel("Line chart of \(kind.label) over the last \(range) days")
            }
        }
        .glassCard()
    }

    /// Converts a canonical stored value into the displayed-unit value for charts.
    private func displayValue(_ value: Double, kind: VitalKind) -> Double {
        switch kind {
        case .weight:  return weightUnit.fromKg(value)
        case .glucose: return glucoseUnit.fromMgdl(value)
        default:       return value
        }
    }

    /// Converts a canonical trend delta into displayed units so the chip matches.
    /// Both conversions are linear through the origin, so the delta scales by the
    /// same factor as the value.
    private func displayTrend(_ trend: VitalsEngine.Trend, kind: VitalKind) -> VitalsEngine.Trend {
        let delta: Double
        switch kind {
        case .weight:  delta = weightUnit.fromKg(trend.delta)
        case .glucose: delta = glucoseUnit.fromMgdl(trend.delta)
        default:       delta = trend.delta
        }
        return VitalsEngine.Trend(delta: delta, direction: trend.direction)
    }
}
