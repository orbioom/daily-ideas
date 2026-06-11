import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Scenario.createdAt) private var scenarios: [Scenario]
    @AppStorage("currencySymbol") private var currencySymbol = "$"
    @AppStorage("didSeedScenario") private var didSeedScenario = false
    @State private var creating = false

    private var primary: Scenario? {
        scenarios.first(where: \.isPrimary) ?? scenarios.first
    }

    var body: some View {
        NavigationStack {
            Group {
                if let scenario = primary {
                    ScrollView {
                        DashboardContent(scenario: scenario, symbol: currencySymbol)
                            .padding(16)
                    }
                } else {
                    EmptyStateView(
                        icon: "sunrise",
                        title: "No plan yet",
                        message: "Create your first scenario — age, savings, contributions — and Horizon will chart your path to financial independence.",
                        actionTitle: "Create a scenario"
                    ) { creating = true }
                }
            }
            .background(Theme.bgPrimary)
            .navigationTitle("Horizon")
            .sheet(isPresented: $creating) {
                ScenarioEditorView(scenario: nil)
            }
            .onAppear(perform: seedIfNeeded)
        }
    }

    private func seedIfNeeded() {
        guard !didSeedScenario, scenarios.isEmpty else { return }
        didSeedScenario = true
        let sample = Scenario(name: "My plan", isPrimary: true)
        context.insert(sample)
    }
}

private struct DashboardContent: View {
    let scenario: Scenario
    let symbol: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var result: FireEngine.Result { FireEngine.evaluate(scenario) }

    var body: some View {
        let r = result
        VStack(spacing: 16) {
            progressCard(r)
            coastCard(r)
            chartCard(r)
            milestonesCard(r)
            assumptionsCard
        }
        .onAppear {
            if reduceMotion { appeared = true } else {
                withAnimation(.easeOut(duration: 0.9)) { appeared = true }
            }
        }
    }

    private func progressCard(_ r: FireEngine.Result) -> some View {
        VStack(spacing: 14) {
            Text(scenario.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            ZStack {
                Circle()
                    .stroke(Theme.accent.opacity(0.15), lineWidth: 16)
                Circle()
                    .trim(from: 0, to: appeared ? r.progress : 0)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 4) {
                    Text("\(Int((r.progress * 100).rounded()))%")
                        .font(.system(size: 42, weight: .bold, design: .serif))
                        .foregroundStyle(Theme.textPrimary)
                    Text("to financial\nindependence")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .frame(width: 190, height: 190)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Progress to financial independence")
            .accessibilityValue("\(Int((r.progress * 100).rounded())) percent")

            HStack(spacing: 12) {
                VStack(spacing: 3) {
                    Text(FireEngine.money(scenario.currentInvested, symbol: symbol, compact: true))
                        .font(.system(.title3, design: .serif, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("invested today").font(.caption2).foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 3) {
                    Text(FireEngine.money(r.fireNumber, symbol: symbol, compact: true))
                        .font(.system(.title3, design: .serif, weight: .bold))
                        .foregroundStyle(Theme.gold)
                    Text("FIRE number").font(.caption2).foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 3) {
                    Text(r.fiAge.map { FireEngine.age($0) } ?? "—")
                        .font(.system(.title3, design: .serif, weight: .bold))
                        .foregroundStyle(Theme.accent)
                    Text("FI age").font(.caption2).foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .horizonCard()
    }

    private func coastCard(_ r: FireEngine.Result) -> some View {
        let coasting = scenario.currentInvested >= r.coastNumber
        return VStack(alignment: .leading, spacing: 8) {
            Label(coasting ? "You've reached Coast FIRE 🎉" : "Coast FIRE",
                  systemImage: "sailboat")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(coasting ? Theme.accent : Theme.textPrimary)
            if coasting {
                Text("Your \(FireEngine.money(scenario.currentInvested, symbol: symbol, compact: true)) can grow to your FIRE number by age \(scenario.targetRetirementAge) with **no further contributions**. Anything you add now buys earlier freedom.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                Text("With \(FireEngine.money(r.coastNumber, symbol: symbol, compact: true)) invested, growth alone would carry you to FI by \(scenario.targetRetirementAge). You're \(Int((r.coastProgress * 100).rounded()))% of the way there\(r.coastAge.map { " — projected to cross at age \(FireEngine.age($0))" } ?? "").")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                ProgressView(value: r.coastProgress)
                    .tint(Theme.gold)
                    .accessibilityLabel("Coast FIRE progress")
                    .accessibilityValue("\(Int((r.coastProgress * 100).rounded())) percent")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .horizonCard()
    }

    private func chartCard(_ r: FireEngine.Result) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Projection — today's money")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            if r.projection.count < 2 {
                Text("Add a longer horizon (target age above current age) to see a projection.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(height: 80)
            } else {
                Chart {
                    ForEach(Array(zip(r.pessimistic, r.optimistic)), id: \.0.id) { pess, opt in
                        AreaMark(
                            x: .value("Age", pess.age),
                            yStart: .value("Low", pess.balance),
                            yEnd: .value("High", opt.balance)
                        )
                        .foregroundStyle(Theme.accent.opacity(0.10))
                    }
                    ForEach(r.projection) { point in
                        LineMark(
                            x: .value("Age", point.age),
                            y: .value("Balance", point.balance)
                        )
                        .foregroundStyle(Theme.accent)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                    }
                    RuleMark(y: .value("FIRE", r.fireNumber))
                        .foregroundStyle(Theme.gold.opacity(0.8))
                        .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                        .annotation(position: .top, alignment: .leading) {
                            Text("FIRE \(FireEngine.money(r.fireNumber, symbol: symbol, compact: true))")
                                .font(.caption2)
                                .foregroundStyle(Theme.gold)
                        }
                    if let fiAge = r.fiAge {
                        RuleMark(x: .value("FI age", fiAge))
                            .foregroundStyle(Theme.textSecondary.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(FireEngine.money(v, symbol: symbol, compact: true))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 220)
                .accessibilityLabel("Projected portfolio balance by age, with optimistic and pessimistic bands")
                Text("Band: expected return ±2 pp. All values inflation-adjusted.")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .horizonCard()
    }

    private func milestonesCard(_ r: FireEngine.Result) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Milestones")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.bottom, 6)
            milestoneRow("Coast FIRE", FireEngine.money(r.coastNumber, symbol: symbol, compact: true),
                         reached: scenario.currentInvested >= r.coastNumber,
                         note: "growth alone finishes the job by \(scenario.targetRetirementAge)")
            Divider()
            milestoneRow("Lean FIRE", FireEngine.money(r.leanFireNumber, symbol: symbol, compact: true),
                         reached: scenario.currentInvested >= r.leanFireNumber,
                         note: "covers 70% of planned spending")
            Divider()
            milestoneRow("FIRE", FireEngine.money(r.fireNumber, symbol: symbol, compact: true),
                         reached: scenario.currentInvested >= r.fireNumber,
                         note: "full spending at a \(String(format: "%.1f", scenario.swrPct))% withdrawal rate")
            Divider()
            milestoneRow("Fat FIRE", FireEngine.money(r.fatFireNumber, symbol: symbol, compact: true),
                         reached: scenario.currentInvested >= r.fatFireNumber,
                         note: "covers 130% of planned spending")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .horizonCard()
    }

    private func milestoneRow(_ name: String, _ amount: String, reached: Bool, note: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: reached ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(reached ? Theme.accent : Theme.textSecondary.opacity(0.5))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(note)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Text(amount)
                .font(.system(.subheadline, design: .serif, weight: .bold))
                .foregroundStyle(reached ? Theme.accent : Theme.textPrimary)
        }
        .padding(.vertical, 7)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(amount), \(reached ? "reached" : "not yet reached")")
    }

    private var assumptionsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("This plan assumes")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("\(FireEngine.money(scenario.monthlyContribution, symbol: symbol))/mo contributions · \(String(format: "%.1f", scenario.expectedReturnPct))% nominal return · \(String(format: "%.1f", scenario.inflationPct))% inflation · \(FireEngine.money(scenario.annualSpending, symbol: symbol, compact: true))/yr retirement spending · target age \(scenario.targetRetirementAge)")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            Text("Horizon is a planning tool, not financial advice.")
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .horizonCard()
    }
}
