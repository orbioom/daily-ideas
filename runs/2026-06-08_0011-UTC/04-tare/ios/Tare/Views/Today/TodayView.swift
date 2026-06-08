import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WeightEntry.date, order: .reverse) private var entries: [WeightEntry]

    @AppStorage("tare.unit") private var unitRaw = WeightUnit.kg.rawValue
    @AppStorage("tare.goalKg") private var goalKg = 0.0
    @AppStorage("tare.smoothing") private var smoothing = 0.1

    @State private var showingAdd = false

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }
    private var engine: TrendEngine { TrendEngine.build(entries: entries, alpha: smoothing) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 20) {
                        if entries.isEmpty {
                            emptyState
                        } else {
                            trendCard
                            rateCard
                            if goalKg > 0 { projectionCard }
                        }
                        Button {
                            showingAdd = true
                        } label: { Label("Add weigh-in", systemImage: "plus") }
                            .buttonStyle(InkButtonStyle())
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Tare")
            .sheet(isPresented: $showingAdd) {
                AddWeightSheet(existing: nil, defaultKg: engine.currentRaw)
            }
        }
    }

    private var emptyState: some View {
        VStack {
            EmptyStateView(icon: "scalemass.fill", title: "No weigh-ins yet",
                           message: "Add your first weight, then keep a simple daily habit. Tare turns it into a calm trend.")
            Button("Load 60 days of sample data") {
                SampleData.load(into: context); Haptics.success()
            }
            .buttonStyle(GlassButtonStyle())
        }
    }

    private var trendCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "TREND WEIGHT")
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(Units.display(engine.currentTrend ?? 0, unit: unit))
                        .font(Brand.mono(40, weight: .semibold))
                        .foregroundStyle(Brand.text)
                        .minimumScaleFactor(0.6).lineLimit(1)
                    if let change = engine.totalChange, abs(change) > 0.05 {
                        Text(Units.deltaDisplay(change, unit: unit))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(change < 0 ? Brand.live : Brand.warn)
                    }
                }
                Sparkline(values: engine.points.suffix(30).map { $0.trend }, tint: Brand.info)
                    .frame(height: 44)
                HStack {
                    Text("Latest weigh-in: \(Units.display(engine.currentRaw ?? 0, unit: unit))")
                        .font(.footnote).foregroundStyle(Brand.text2)
                    Spacer()
                    Text("\(entries.count) entries").font(Brand.mono(11)).foregroundStyle(Brand.text3)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var rateCard: some View {
        GlassCard {
            HStack(spacing: 16) {
                Image(systemName: rateSymbol)
                    .font(.title2)
                    .foregroundStyle(rateColor)
                    .frame(width: 40)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    if let rate = engine.ratePerWeek {
                        Text(Units.deltaDisplay(rate, unit: unit) + " / week")
                            .font(.headline).foregroundStyle(Brand.text)
                        Text("Based on the last 30 days of trend.")
                            .font(.footnote).foregroundStyle(Brand.text2)
                    } else {
                        Text("Gathering data").font(.headline).foregroundStyle(Brand.text)
                        Text("Log a few more days to estimate your rate.")
                            .font(.footnote).foregroundStyle(Brand.text2)
                    }
                }
                Spacer()
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var projectionCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: "GOAL \(Units.display(goalKg, unit: unit, decimals: 0))")
                if let date = engine.projectedDate(goalKg) {
                    Text(Format.target.string(from: date))
                        .font(Brand.mono(24, weight: .semibold)).foregroundStyle(Brand.magic)
                    if let days = engine.daysToGoal(goalKg) {
                        Text("About \(days) days away at your current pace.")
                            .font(.footnote).foregroundStyle(Brand.text2)
                    }
                } else {
                    Text("Not trending toward goal")
                        .font(.headline).foregroundStyle(Brand.text)
                    Text("Your trend is flat or moving the other way right now.")
                        .font(.footnote).foregroundStyle(Brand.text2)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var rateSymbol: String {
        guard let r = engine.ratePerWeek else { return "questionmark.circle" }
        if r < -0.05 { return "arrow.down.right.circle.fill" }
        if r > 0.05 { return "arrow.up.right.circle.fill" }
        return "arrow.right.circle.fill"
    }
    private var rateColor: Color {
        guard let r = engine.ratePerWeek else { return Brand.text3 }
        if r < -0.05 { return Brand.live }
        if r > 0.05 { return Brand.warn }
        return Brand.text2
    }
}
