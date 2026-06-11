import SwiftUI
import SwiftData
import Charts

struct CompareView: View {
    @Query(sort: \Scenario.createdAt) private var scenarios: [Scenario]
    @AppStorage("currencySymbol") private var currencySymbol = "$"

    private let palette: [Color] = [Theme.accent, Theme.gold, .cyan, .pink, .indigo, .orange]

    var body: some View {
        NavigationStack {
            Group {
                if scenarios.count < 2 {
                    EmptyStateView(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Nothing to compare yet",
                        message: "Create at least two scenarios — say, your current path and a \u{201C}save \(currencySymbol)500 more\u{201D} path — and see them race here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            chartCard
                            tableCard
                        }
                        .padding(16)
                    }
                }
            }
            .background(Theme.bgPrimary)
            .navigationTitle("Compare")
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Balance by age — today's money")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Chart {
                ForEach(Array(scenarios.enumerated()), id: \.element.persistentModelID) { index, scenario in
                    let result = FireEngine.evaluate(scenario)
                    ForEach(result.projection) { point in
                        LineMark(
                            x: .value("Age", point.age),
                            y: .value("Balance", point.balance),
                            series: .value("Scenario", scenario.name + "\(index)")
                        )
                        .foregroundStyle(palette[index % palette.count])
                        .lineStyle(StrokeStyle(lineWidth: 2.2))
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(FireEngine.money(v, symbol: currencySymbol, compact: true))
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 240)
            .accessibilityLabel("Comparison chart of projected balances for each scenario")

            // Legend
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(scenarios.enumerated()), id: \.element.persistentModelID) { index, scenario in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(palette[index % palette.count])
                            .frame(width: 8, height: 8)
                        Text(scenario.name)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .horizonCard()
    }

    private var tableCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Head to head")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.bottom, 6)
            ForEach(Array(scenarios.enumerated()), id: \.element.persistentModelID) { index, scenario in
                let result = FireEngine.evaluate(scenario)
                HStack(spacing: 10) {
                    Circle()
                        .fill(palette[index % palette.count])
                        .frame(width: 8, height: 8)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(scenario.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("FIRE \(FireEngine.money(result.fireNumber, symbol: currencySymbol, compact: true)) · coast \(FireEngine.money(result.coastNumber, symbol: currencySymbol, compact: true))")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Text(result.fiAge.map { "FI \(FireEngine.age($0))" } ?? "—")
                        .font(.system(.subheadline, design: .serif, weight: .bold))
                        .foregroundStyle(result.fiAge == nil ? Theme.textSecondary : Theme.accent)
                }
                .padding(.vertical, 7)
                .accessibilityElement(children: .combine)
                if index < scenarios.count - 1 { Divider() }
            }
            if let best = bestScenario {
                Text("Earliest independence: **\(best.name)**")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .horizonCard()
    }

    private var bestScenario: Scenario? {
        scenarios.min { a, b in
            let fa = FireEngine.evaluate(a).fiAge ?? .infinity
            let fb = FireEngine.evaluate(b).fiAge ?? .infinity
            return fa < fb
        }
    }
}
