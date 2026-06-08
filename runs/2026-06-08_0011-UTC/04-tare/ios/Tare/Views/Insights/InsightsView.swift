import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query(sort: \WeightEntry.date, order: .reverse) private var entries: [WeightEntry]
    @AppStorage("tare.unit") private var unitRaw = WeightUnit.kg.rawValue
    @AppStorage("tare.goalKg") private var goalKg = 0.0
    @AppStorage("tare.heightCm") private var heightCm = 0.0
    @AppStorage("tare.smoothing") private var smoothing = 0.1

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }
    private var engine: TrendEngine { TrendEngine.build(entries: entries, alpha: smoothing) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if entries.isEmpty {
                    EmptyStateView(icon: "sparkles", title: "No insights yet",
                                   message: "Log weigh-ins to unlock your rate, BMI, and goal milestones.")
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            summaryCard
                            if let bmi = bmiValue { bmiCard(bmi) }
                            if goalKg > 0 { milestonesCard }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var summaryCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    StatTile(value: Units.display(engine.currentTrend ?? 0, unit: unit, decimals: 1), label: "Trend now")
                    StatTile(value: rateText, label: "Per week", tint: rateColor)
                }
                Divider().overlay(Brand.hairline)
                HStack(spacing: 12) {
                    StatTile(value: changeText, label: "Total change",
                             tint: (engine.totalChange ?? 0) < 0 ? Brand.live : Brand.text)
                    StatTile(value: "\(entries.count)", label: "Weigh-ins")
                }
            }
        }
    }

    private func bmiCard(_ bmi: Double) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: "BODY MASS INDEX")
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(String(format: "%.1f", bmi))
                        .font(Brand.mono(34, weight: .semibold)).foregroundStyle(Brand.text)
                    Text(TrendEngine.bmiCategory(bmi))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(bmi >= 18.5 && bmi < 25 ? Brand.live : Brand.warn)
                }
                Text("From your trend weight and height of \(Int(heightCm)) cm. BMI is a rough guide, not a diagnosis.")
                    .font(.footnote).foregroundStyle(Brand.text3)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var milestonesCard: some View {
        let current = engine.currentTrend ?? 0
        let start = engine.startTrend ?? current
        // Build 1-unit milestones between start and goal.
        let losing = goalKg < start
        let stepKg = unit == .kg ? 1.0 : (1.0 / Units.lbPerKg) * 5 // ~5 lb steps when imperial
        var marks: [Double] = []
        if losing {
            var m = (start - stepKg)
            while m > goalKg - 0.01 { marks.append(max(m, goalKg)); m -= stepKg }
        } else {
            var m = (start + stepKg)
            while m < goalKg + 0.01 { marks.append(min(m, goalKg)); m += stepKg }
        }
        marks = Array(marks.prefix(12))
        return GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "MILESTONES")
                if marks.isEmpty {
                    Text("Set a goal that differs from your starting weight.")
                        .font(.subheadline).foregroundStyle(Brand.text2)
                }
                ForEach(Array(marks.enumerated()), id: \.offset) { _, mark in
                    let reached = losing ? current <= mark + 0.05 : current >= mark - 0.05
                    HStack {
                        Image(systemName: reached ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(reached ? Brand.live : Brand.text3)
                        Text(Units.display(mark, unit: unit, decimals: 0))
                            .font(.subheadline).foregroundStyle(reached ? Brand.text2 : Brand.text)
                        Spacer()
                        if reached { Text("Reached").font(.caption).foregroundStyle(Brand.live) }
                    }
                }
            }
        }
    }

    private var bmiValue: Double? {
        guard heightCm > 0, let kg = engine.currentTrend else { return nil }
        return TrendEngine.bmi(kg: kg, heightCm: heightCm)
    }
    private var rateText: String {
        engine.ratePerWeek.map { Units.deltaDisplay($0, unit: unit) } ?? "—"
    }
    private var rateColor: Color {
        guard let r = engine.ratePerWeek else { return Brand.text }
        return r < -0.05 ? Brand.live : (r > 0.05 ? Brand.warn : Brand.text)
    }
    private var changeText: String {
        engine.totalChange.map { Units.deltaDisplay($0, unit: unit) } ?? "—"
    }
}
