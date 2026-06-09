import SwiftUI
import SwiftData
import Charts

struct ProgressTabView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \BodyMetric.date) private var metrics: [BodyMetric]
    @Query(sort: \ProgressPhoto.date) private var photos: [ProgressPhoto]

    @AppStorage("contour.weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue
    @AppStorage("contour.lengthUnit") private var lengthUnitRaw = LengthUnit.cm.rawValue
    @AppStorage("contour.goalWeightKg") private var goalWeightKg = 0.0

    @State private var editingType: MetricType?

    private var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .kg }
    private var lengthUnit: LengthUnit { LengthUnit(rawValue: lengthUnitRaw) ?? .cm }
    private var goalKg: Double? { goalWeightKg > 0 ? goalWeightKg : nil }

    private var summaries: [ContourEngine.MetricSummary] {
        ContourEngine.allSummaries(in: metrics)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                content
            }
            .navigationTitle("Progress")
            .sheet(item: $editingType) { type in
                MetricLogSheet(type: type)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if metrics.isEmpty && photos.isEmpty {
            EmptyStateView(icon: "chart.xyaxis.line",
                           title: "No measurements yet",
                           message: "Log a weight or measurement and your trend charts will appear here.")
        } else {
            ScrollView {
                VStack(spacing: 18) {
                    statTiles
                    weightCard
                    ForEach(otherSummaries, id: \.type) { summary in
                        metricCard(summary)
                    }
                }
                .padding(16)
            }
        }
    }

    private var otherSummaries: [ContourEngine.MetricSummary] {
        summaries.filter { $0.type != .weight }
    }

    // MARK: - Stat tiles

    private var statTiles: some View {
        HStack(spacing: 10) {
            StatTile(value: "\(ContourEngine.loggingStreak(photos: photos, metrics: metrics))",
                     label: "Day streak", tint: Brand.magic)
            StatTile(value: "\(photos.count)", label: "Photos")
            StatTile(value: "\(ContourEngine.spanDays(photos: photos, metrics: metrics))",
                     label: "Days tracked")
        }
    }

    // MARK: - Weight card (raw + EMA + goal line)

    @ViewBuilder
    private var weightCard: some View {
        let trend = ContourEngine.weightTrend(in: metrics, goalWeightKg: goalKg)
        if trend.raw.isEmpty {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    metricHeader(type: .weight,
                                 current: nil, delta: nil)
                    Text("Log your weight to see the trend.")
                        .font(.subheadline).foregroundStyle(Brand.text2)
                }
            }
        } else {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    metricHeader(type: .weight,
                                 current: trend.raw.last?.value,
                                 delta: trend.changeSinceStart)

                    Chart {
                        ForEach(trend.raw) { p in
                            LineMark(x: .value("Date", p.date),
                                     y: .value("Weight", display(p.value, .weight)),
                                     series: .value("Series", "Readings"))
                            .foregroundStyle(Brand.text3.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1))
                            .symbol(.circle).symbolSize(12)
                        }
                        ForEach(trend.ema) { p in
                            LineMark(x: .value("Date", p.date),
                                     y: .value("Trend", display(p.value, .weight)),
                                     series: .value("Series", "Trend"))
                            .foregroundStyle(Brand.magic)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                            .interpolationMethod(.catmullRom)
                        }
                        if let goal = goalKg {
                            RuleMark(y: .value("Goal", display(goal, .weight)))
                                .foregroundStyle(Brand.info)
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5]))
                                .annotation(position: .top, alignment: .leading) {
                                    Text("Goal \(Units.formattedWeight(goal, unit: weightUnit))")
                                        .font(Brand.mono(10, weight: .medium))
                                        .foregroundStyle(Brand.info)
                                }
                        }
                    }
                    .frame(height: 180)
                    .chartYAxis { AxisMarks(position: .leading) }
                    .accessibilityLabel("Weight trend chart")
                    .accessibilityValue(weightAccessibilitySummary(trend))

                    trendFooter(trend)
                }
            }
        }
    }

    private func trendFooter(_ trend: ContourEngine.WeightTrend) -> some View {
        VStack(spacing: 8) {
            if let rate = trend.ratePerWeek {
                row("Rate", "\(Units.signed(Units.kgToDisplay(rate, unit: weightUnit))) \(weightUnit.short)/week")
            }
            if let c30 = trend.change30d {
                row("Last 30 days", "\(Units.signed(Units.kgToDisplay(c30, unit: weightUnit))) \(weightUnit.short)")
            }
            if let projected = trend.projectedDateToGoal {
                row("Goal projection", "~\(Format.shortDayYear.string(from: projected))")
            } else if goalKg != nil, trend.ratePerWeek != nil {
                row("Goal projection", "Not on pace")
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Brand.text2)
            Spacer()
            Text(value).font(Brand.mono(14, weight: .medium)).foregroundStyle(Brand.text)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Other metric cards

    private func metricCard(_ summary: ContourEngine.MetricSummary) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                metricHeader(type: summary.type, current: summary.current, delta: summary.delta)
                if summary.series.count >= 2 {
                    Chart(summary.series) { p in
                        LineMark(x: .value("Date", p.date),
                                 y: .value(summary.type.label, display(p.value, summary.type)))
                        .foregroundStyle(Brand.magic)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                        AreaMark(x: .value("Date", p.date),
                                 y: .value(summary.type.label, display(p.value, summary.type)))
                        .foregroundStyle(LinearGradient(colors: [Brand.magic.opacity(0.25), .clear],
                                                        startPoint: .top, endPoint: .bottom))
                    }
                    .frame(height: 120)
                    .chartYAxis { AxisMarks(position: .leading) }
                    .accessibilityLabel("\(summary.type.label) trend chart")
                    .accessibilityValue(metricAccessibilitySummary(summary))
                } else {
                    Text("One reading so far — add another to see a trend.")
                        .font(.footnote).foregroundStyle(Brand.text3)
                }
            }
        }
    }

    // MARK: - Shared header

    private func metricHeader(type: MetricType, current: Double?, delta: Double?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Label(type.label, systemImage: type.symbol)
                .font(.headline).foregroundStyle(Brand.text)
            Spacer()
            if let current {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Units.formatted(current, type: type, weightUnit: weightUnit, lengthUnit: lengthUnit))
                        .font(Brand.mono(16, weight: .semibold)).foregroundStyle(Brand.text)
                    if let delta {
                        let dd = Units.displayDelta(delta, type: type, weightUnit: weightUnit, lengthUnit: lengthUnit)
                        Text("\(Units.signed(dd)) \(Units.suffix(for: type, weightUnit: weightUnit, lengthUnit: lengthUnit))")
                            .font(Brand.mono(11, weight: .medium))
                            .foregroundStyle(delta < 0 ? Brand.live : (delta > 0 ? Brand.warn : Brand.text3))
                    }
                }
            }
            Button {
                Haptics.tap()
                editingType = type
            } label: {
                Image(systemName: "plus.circle")
                    .font(.title3)
                    .foregroundStyle(Brand.magic)
            }
            .accessibilityLabel("Add \(type.label) reading")
        }
    }

    // MARK: - Helpers

    private func display(_ canonical: Double, _ type: MetricType) -> Double {
        Units.displayValue(canonical, type: type, weightUnit: weightUnit, lengthUnit: lengthUnit)
    }

    private func weightAccessibilitySummary(_ trend: ContourEngine.WeightTrend) -> String {
        guard let last = trend.raw.last?.value else { return "No data" }
        var parts = ["Current \(Units.formattedWeight(last, unit: weightUnit))"]
        if let c = trend.changeSinceStart {
            parts.append("change \(Units.signed(Units.kgToDisplay(c, unit: weightUnit))) \(weightUnit.short)")
        }
        return parts.joined(separator: ", ")
    }

    private func metricAccessibilitySummary(_ s: ContourEngine.MetricSummary) -> String {
        let cur = Units.formatted(s.current, type: s.type, weightUnit: weightUnit, lengthUnit: lengthUnit)
        let startD = display(s.starting, s.type)
        let curD = display(s.current, s.type)
        return "Current \(cur), change \(Units.signed(curD - startD)) \(Units.suffix(for: s.type, weightUnit: weightUnit, lengthUnit: lengthUnit))"
    }
}

/// Quick sheet to add a reading for a specific metric type.
struct MetricLogSheet: View {
    let type: MetricType
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("contour.weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue
    @AppStorage("contour.lengthUnit") private var lengthUnitRaw = LengthUnit.cm.rawValue

    @State private var valueText = ""
    @State private var date = Date()
    @State private var note = ""

    private var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .kg }
    private var lengthUnit: LengthUnit { LengthUnit(rawValue: lengthUnitRaw) ?? .cm }
    private var suffix: String { Units.suffix(for: type, weightUnit: weightUnit, lengthUnit: lengthUnit) }

    private var invalid: Bool {
        let t = valueText.trimmingCharacters(in: .whitespaces)
        guard let v = Double(t) else { return true }
        return v <= 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("New \(type.label) reading") {
                    HStack {
                        Text("Value (\(suffix))")
                        Spacer()
                        TextField("0", text: $valueText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Note (optional)", text: $note, axis: .vertical).lineLimit(1...3)
                }
            }
            .navigationTitle(type.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(invalid)
                }
            }
        }
    }

    private func save() {
        let t = valueText.trimmingCharacters(in: .whitespaces)
        guard let v = Double(t), v > 0 else { return }
        let canonical = Units.canonicalValue(v, type: type, weightUnit: weightUnit, lengthUnit: lengthUnit)
        context.insert(BodyMetric(date: date, type: type, value: canonical,
                                  note: note.trimmingCharacters(in: .whitespaces)))
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
