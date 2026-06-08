import SwiftUI
import SwiftData
import Charts

struct TrendsView: View {
    @Query private var allEntries: [DiaryEntry]
    @Query private var goals: [UserGoal]
    @State private var rangeOption: RangeOption = .fourteenDays

    private var goal: UserGoal? { goals.first }

    enum RangeOption: String, CaseIterable, Identifiable {
        case fourteenDays = "14 Days"
        case thirtyDays   = "30 Days"
        var id: String { rawValue }
        var days: Int { self == .fourteenDays ? 14 : 30 }
    }

    private var dayData: [DayData] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<rangeOption.days).reversed().compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let dayEntries = allEntries.filter { cal.isDate($0.day, inSameDayAs: day) }
            let totals = NutritionEngine.dayTotals(dayEntries)
            return DayData(date: day, calories: totals.calories, protein: totals.protein, carbs: totals.carbs, fat: totals.fat)
        }
    }

    private var calorieTarget: Double { goal?.calorieTarget ?? 2000 }

    private var daysLogged: Int {
        dayData.filter { $0.calories > 0 }.count
    }

    private var daysUnderTarget: Int {
        dayData.filter { $0.calories > 0 && $0.calories <= calorieTarget }.count
    }

    private var avgCalories: Double {
        let logged = dayData.filter { $0.calories > 0 }
        guard !logged.isEmpty else { return 0 }
        return logged.reduce(0) { $0 + $1.calories } / Double(logged.count)
    }

    private var avgMacros: (p: Double, c: Double, f: Double) {
        let logged = dayData.filter { $0.calories > 0 }
        guard !logged.isEmpty else { return (0, 0, 0) }
        let p = logged.reduce(0) { $0 + $1.protein } / Double(logged.count)
        let c = logged.reduce(0) { $0 + $1.carbs }   / Double(logged.count)
        let f = logged.reduce(0) { $0 + $1.fat }     / Double(logged.count)
        return (p, c, f)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 20) {
                        // Range toggle
                        Picker("Range", selection: $rangeOption) {
                            ForEach(RangeOption.allCases) { opt in
                                Text(opt.rawValue).tag(opt)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)

                        if daysLogged == 0 {
                            EmptyStateView(
                                icon: "chart.bar",
                                title: "No data yet",
                                message: "Log meals in the Diary tab and your calorie trends will appear here."
                            )
                        } else {
                            statsCards
                            caloriesChart
                            macroDistribution
                            proteinTrend
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Trends")
        }
    }

    // MARK: - Stats summary

    private var statsCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Avg. Calories", value: Format.kcalShort(avgCalories), unit: "kcal/day", color: Brand.magic)
            StatCard(title: "Days Logged", value: "\(daysLogged)", unit: "of \(rangeOption.days)", color: Brand.info)
            StatCard(title: "Under Target", value: "\(daysUnderTarget)", unit: "days", color: Brand.live)
            StatCard(title: "vs. Target", value: Format.kcalDelta(avgCalories - calorieTarget), unit: "avg kcal", color: avgCalories <= calorieTarget ? Brand.live : Brand.danger)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Calories bar chart

    private var caloriesChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Calories / Day")
                Text("Daily intake vs. target")
                    .font(.headline)
                    .foregroundStyle(Brand.text)

                Chart {
                    ForEach(dayData) { day in
                        BarMark(
                            x: .value("Date", day.date, unit: .day),
                            y: .value("Calories", day.calories)
                        )
                        .foregroundStyle(day.calories > calorieTarget ? Brand.danger : Brand.magic)
                        .cornerRadius(4)
                    }

                    RuleMark(y: .value("Target", calorieTarget))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5]))
                        .foregroundStyle(Brand.warn)
                        .annotation(position: .trailing, alignment: .leading) {
                            Text("Goal")
                                .font(Brand.mono(9))
                                .foregroundStyle(Brand.warn)
                        }
                }
                .frame(height: 180)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: rangeOption.days == 14 ? 2 : 5)) { _ in
                        AxisValueLabel(format: .dateTime.day())
                            .foregroundStyle(Brand.text3)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Brand.text3)
                        AxisGridLine()
                            .foregroundStyle(Brand.hairline)
                    }
                }
                .accessibilityLabel("Bar chart showing daily calorie intake over the past \(rangeOption.days) days")
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Macro distribution donut

    private var macroDistribution: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Macro Distribution")
                Text("Average daily split")
                    .font(.headline)
                    .foregroundStyle(Brand.text)

                let avgs = avgMacros
                let pKcal = avgs.p * 4
                let cKcal = avgs.c * 4
                let fKcal = avgs.f * 9
                let total = pKcal + cKcal + fKcal
                let pPct = total > 0 ? pKcal / total : 0
                let cPct = total > 0 ? cKcal / total : 0
                let fPct = total > 0 ? fKcal / total : 0

                let slices: [(String, Double, Color)] = [
                    ("Protein", pKcal, Brand.danger),
                    ("Carbs",   cKcal, Brand.warn),
                    ("Fat",     fKcal, Brand.info),
                ]

                HStack(spacing: 24) {
                    Chart {
                        ForEach(slices, id: \.0) { slice in
                            SectorMark(
                                angle: .value(slice.0, slice.1),
                                innerRadius: .ratio(0.55),
                                angularInset: 2
                            )
                            .foregroundStyle(slice.2)
                        }
                    }
                    .frame(width: 120, height: 120)
                    .accessibilityLabel("Donut chart: protein \(Format.percent(pPct)), carbs \(Format.percent(cPct)), fat \(Format.percent(fPct))")

                    VStack(alignment: .leading, spacing: 8) {
                        macroLegend(label: "Protein", grams: avgs.p, pct: pPct, color: Brand.danger)
                        macroLegend(label: "Carbs",   grams: avgs.c, pct: cPct, color: Brand.warn)
                        macroLegend(label: "Fat",     grams: avgs.f, pct: fPct, color: Brand.info)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func macroLegend(label: String, grams: Double, pct: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8).accessibilityHidden(true)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Brand.text2)
            Spacer()
            Text(Format.grams(grams))
                .font(Brand.mono(12, weight: .medium))
                .foregroundStyle(Brand.text)
            Text(Format.percent(pct))
                .font(Brand.mono(10))
                .foregroundStyle(Brand.text3)
        }
    }

    // MARK: - Protein trend line

    private var proteinTrend: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Protein Trend")
                Text("Daily protein intake (g)")
                    .font(.headline)
                    .foregroundStyle(Brand.text)

                Chart {
                    ForEach(dayData) { day in
                        LineMark(
                            x: .value("Date", day.date, unit: .day),
                            y: .value("Protein", day.protein)
                        )
                        .foregroundStyle(Brand.danger)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Date", day.date, unit: .day),
                            y: .value("Protein", day.protein)
                        )
                        .foregroundStyle(Brand.danger.opacity(0.12))
                        .interpolationMethod(.catmullRom)
                    }

                    if let proteinGoal = goal?.proteinTarget {
                        RuleMark(y: .value("Target", proteinGoal))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4]))
                            .foregroundStyle(Brand.warn)
                    }
                }
                .frame(height: 140)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: rangeOption.days == 14 ? 2 : 5)) { _ in
                        AxisValueLabel(format: .dateTime.day())
                            .foregroundStyle(Brand.text3)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel().foregroundStyle(Brand.text3)
                        AxisGridLine().foregroundStyle(Brand.hairline)
                    }
                }
                .accessibilityLabel("Line chart showing daily protein intake over the past \(rangeOption.days) days")
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Supporting types

private struct DayData: Identifiable {
    var id: Date { date }
    let date: Date
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}

private struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
                Text(value)
                    .font(Brand.mono(22, weight: .semibold))
                    .foregroundStyle(color)
                    .minimumScaleFactor(0.7)
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(Brand.text3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value) \(unit)")
    }
}
