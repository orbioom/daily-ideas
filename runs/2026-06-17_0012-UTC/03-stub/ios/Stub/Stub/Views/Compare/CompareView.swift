import SwiftUI
import SwiftData
import Charts

/// Pick 2–3 saved scenarios and compare net pay side by side.
/// Free tier: 2-way. Pro: 3-way + multi-frequency detail.
struct CompareView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppPreferences.self) private var prefs
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \PayScenario.createdAt, order: .reverse) private var scenarios: [PayScenario]

    @State private var selectedIDs: [UUID] = []
    @State private var showPaywall = false

    private var maxSelectable: Int { isPro ? 3 : 2 }

    private var selectedScenarios: [PayScenario] {
        selectedIDs.compactMap { id in scenarios.first(where: { $0.id == id }) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if scenarios.count < 2 {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            pickerCard
                            if selectedScenarios.count >= 2 {
                                chartCard
                                tableCard
                                winnerCard
                            } else {
                                hintCard
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(StubTheme.appBackground(scheme).ignoresSafeArea())
            .navigationTitle("Compare")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onAppear(perform: preselect)
        }
    }

    private func preselect() {
        guard selectedIDs.isEmpty else { return }
        selectedIDs = Array(scenarios.prefix(2)).map(\.id)
    }

    // MARK: - Cards

    private var pickerCard: some View {
        StubCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Choose scenarios")
                        .font(.headline)
                        .foregroundStyle(StubTheme.primaryText(scheme))
                    Spacer()
                    Text("\(selectedIDs.count)/\(maxSelectable)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(StubTheme.secondaryText(scheme))
                }
                ForEach(scenarios) { scenario in
                    let isOn = selectedIDs.contains(scenario.id)
                    Button {
                        toggle(scenario)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isOn ? StubTheme.green : StubTheme.secondaryText(scheme))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(scenario.name)
                                    .foregroundStyle(StubTheme.primaryText(scheme))
                                Text(Format.currency(scenario.result.netPerPaycheck, whole: prefs.roundWhole) + " / paycheck")
                                    .font(.caption)
                                    .foregroundStyle(StubTheme.secondaryText(scheme))
                            }
                            Spacer()
                        }
                    }
                    .accessibilityLabel("\(scenario.name), \(isOn ? "selected" : "not selected")")
                }
                if !isPro {
                    Button {
                        showPaywall = true
                    } label: {
                        Label("Compare 3 with Pro", systemImage: "lock.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(StubTheme.green)
                    }
                    .padding(.top, 2)
                }
            }
        }
    }

    private func toggle(_ scenario: PayScenario) {
        if let idx = selectedIDs.firstIndex(of: scenario.id) {
            selectedIDs.remove(at: idx)
        } else {
            if selectedIDs.count >= maxSelectable {
                if !isPro { showPaywall = true; return }
                // Pro at cap: drop the oldest selection.
                if !selectedIDs.isEmpty { selectedIDs.removeFirst() }
            }
            selectedIDs.append(scenario.id)
        }
    }

    private var chartCard: some View {
        StubCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Net pay per paycheck")
                    .font(.headline)
                    .foregroundStyle(StubTheme.primaryText(scheme))
                Chart(selectedScenarios) { scenario in
                    BarMark(
                        x: .value("Scenario", scenario.name),
                        y: .value("Net", scenario.result.netPerPaycheck.doubleValue)
                    )
                    .foregroundStyle(StubTheme.green.gradient)
                    .cornerRadius(6)
                    .annotation(position: .top) {
                        Text(Format.currency(scenario.result.netPerPaycheck, whole: true))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(StubTheme.secondaryText(scheme))
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(Format.currency(Decimal(v), whole: true))
                            }
                        }
                    }
                }
                .frame(height: 220)
                .accessibilityLabel(chartAccessibility)
            }
        }
    }

    private var chartAccessibility: String {
        let parts = selectedScenarios.map {
            "\($0.name): \(Format.currencySpoken($0.result.netPerPaycheck, whole: true)) per paycheck"
        }
        return "Net pay per paycheck. " + parts.joined(separator: ". ")
    }

    private var tableCard: some View {
        StubCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("Side by side")
                    .font(.headline)
                    .foregroundStyle(StubTheme.primaryText(scheme))
                    .padding(.bottom, 12)

                tableRow(label: "", values: selectedScenarios.map(\.name), isHeader: true)
                Divider().background(StubTheme.hairline(scheme)).padding(.vertical, 8)
                tableRow(label: "Net / paycheck",
                         values: selectedScenarios.map { Format.currency($0.result.netPerPaycheck, whole: prefs.roundWhole) })
                tableRow(label: "Net / year",
                         values: selectedScenarios.map { Format.currency($0.result.netAnnual, whole: true) })
                tableRow(label: "Gross / year",
                         values: selectedScenarios.map { Format.currency($0.result.annualGross, whole: true) })
                tableRow(label: "Effective rate",
                         values: selectedScenarios.map { Format.percent($0.result.effectiveTaxRate) })
                tableRow(label: "Take-home %",
                         values: selectedScenarios.map { Format.percent($0.result.takeHomePercent, fractionDigits: 0) })
                tableRow(label: "State",
                         values: selectedScenarios.map { $0.stateCode })
            }
        }
    }

    private func tableRow(label: String, values: [String], isHeader: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(StubTheme.secondaryText(scheme))
                .frame(width: 96, alignment: .leading)
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                Text(value)
                    .font(isHeader ? .caption.weight(.bold) : StubTheme.figureFont(.footnote, weight: .medium))
                    .foregroundStyle(StubTheme.primaryText(scheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
    }

    private var winnerCard: some View {
        let best = selectedScenarios.max(by: { $0.result.netAnnual < $1.result.netAnnual })
        return Group {
            if let best, selectedScenarios.count >= 2 {
                StubCard {
                    HStack(spacing: 12) {
                        Image(systemName: "trophy.fill")
                            .font(.title2)
                            .foregroundStyle(StubTheme.green)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Highest take-home")
                                .font(.caption)
                                .foregroundStyle(StubTheme.secondaryText(scheme))
                            Text(best.name)
                                .font(.headline)
                                .foregroundStyle(StubTheme.primaryText(scheme))
                        }
                        Spacer()
                        Text(Format.currency(best.result.netAnnual, whole: true) + "/yr")
                            .font(StubTheme.figureFont(.subheadline, weight: .bold))
                            .foregroundStyle(StubTheme.green)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Highest take-home: \(best.name), \(Format.currencySpoken(best.result.netAnnual, whole: true)) per year")
                }
            }
        }
    }

    private var hintCard: some View {
        StubCard {
            Text("Select at least two scenarios above to compare them.")
                .font(.subheadline)
                .foregroundStyle(StubTheme.secondaryText(scheme))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "rectangle.split.2x1")
                .font(.system(size: 52))
                .foregroundStyle(StubTheme.green.opacity(0.7))
                .accessibilityHidden(true)
            Text("Save two scenarios to compare")
                .font(.title3.weight(.semibold))
                .foregroundStyle(StubTheme.primaryText(scheme))
            Text("Use the Calculator to save a couple of offers, then compare their net pay side by side here.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(StubTheme.secondaryText(scheme))
                .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}
