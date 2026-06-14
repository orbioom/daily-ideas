import SwiftUI
import SwiftData

struct ScenariosView: View {
    @Binding var selection: RootView.Tab
    @Environment(CalculatorModel.self) private var calc
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var context
    @Query(sort: \LoanScenario.createdAt, order: .reverse) private var scenarios: [LoanScenario]

    @State private var showPaywall = false
    @State private var compareSelection: Set<UUID> = []
    @State private var isCompareMode = false
    @State private var showCompare = false

    private var symbol: String { settings.currency.symbol }
    private var isPro: Bool { UserDefaults.standard.bool(forKey: "isPro") }

    var body: some View {
        NavigationStack {
            Group {
                if scenarios.isEmpty {
                    EmptyStateView(symbol: "square.stack.3d.up",
                                   title: "No saved scenarios",
                                   message: "Save a loan from the Calculator to keep it here, compare options, and revisit anytime.",
                                   actionTitle: "Go to Calculator") {
                        selection = .calculator
                    }
                } else {
                    list
                }
            }
            .background(Theme.bg)
            .navigationTitle("Scenarios")
            .toolbar {
                if !scenarios.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(isCompareMode ? "Done" : "Compare") {
                            toggleCompareMode()
                        }
                        .font(Theme.rounded(15, .medium))
                    }
                }
            }
            .navigationDestination(for: LoanScenario.self) { scenario in
                ScenarioDetailView(scenario: scenario, selection: $selection)
            }
            .sheet(isPresented: $showCompare) {
                let chosen = scenarios.filter { compareSelection.contains($0.id) }
                CompareView(scenarios: chosen)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .safeAreaInset(edge: .bottom) {
                if isCompareMode { compareBar }
            }
        }
    }

    private var list: some View {
        List {
            if isCompareMode {
                Section {
                    Text("Pick two scenarios to compare side by side.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            ForEach(scenarios) { scenario in
                row(for: scenario)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
            }
            .onDelete(perform: delete)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
    }

    @ViewBuilder
    private func row(for scenario: LoanScenario) -> some View {
        if isCompareMode {
            Button {
                toggleSelection(scenario)
            } label: {
                ScenarioCard(scenario: scenario, symbol: symbol,
                             selected: compareSelection.contains(scenario.id),
                             showsCheckbox: true)
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: scenario) {
                ScenarioCard(scenario: scenario, symbol: symbol,
                             selected: false, showsCheckbox: false)
            }
            .buttonStyle(.plain)
        }
    }

    private var compareBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Theme.hairline)
            Button {
                if compareSelection.count == 2 { showCompare = true }
            } label: {
                Text(compareSelection.count == 2
                     ? "Compare these two"
                     : "Select \(2 - compareSelection.count) more")
                    .font(Theme.rounded(16, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(compareSelection.count == 2 ? Theme.accent : Theme.surfaceAlt,
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(compareSelection.count == 2 ? Color.white : Theme.inkFaint)
            }
            .disabled(compareSelection.count != 2)
            .padding(16)
            .background(Theme.bg)
        }
    }

    // MARK: - Actions

    private func toggleCompareMode() {
        if !isCompareMode && !isPro {
            showPaywall = true
            Haptics.warning(enabled: settings.hapticsEnabled)
            return
        }
        isCompareMode.toggle()
        if !isCompareMode { compareSelection.removeAll() }
        Haptics.tap(enabled: settings.hapticsEnabled)
    }

    private func toggleSelection(_ scenario: LoanScenario) {
        if compareSelection.contains(scenario.id) {
            compareSelection.remove(scenario.id)
        } else if compareSelection.count < 2 {
            compareSelection.insert(scenario.id)
            Haptics.tap(enabled: settings.hapticsEnabled)
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets where scenarios.indices.contains(index) {
            let scenario = scenarios[index]
            if calc.loadedScenarioID == scenario.id { calc.loadedScenarioID = nil }
            context.delete(scenario)
        }
        try? context.save()
        Haptics.tap(enabled: settings.hapticsEnabled)
    }
}

/// A summary card for one saved scenario.
struct ScenarioCard: View {
    let scenario: LoanScenario
    let symbol: String
    var selected: Bool
    var showsCheckbox: Bool

    var body: some View {
        let s = scenario.summary
        return HStack(spacing: 14) {
            if showsCheckbox {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(selected ? Theme.accent : Theme.inkFaint)
                    .accessibilityHidden(true)
            }
            ZStack {
                Circle().fill(Theme.accentSoft).frame(width: 44, height: 44)
                Image(systemName: scenario.loanType.symbol)
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(scenario.name)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text("\(Fmt.moneyWhole(scenario.principal, symbol: symbol)) · \(Fmt.percent(scenario.annualRatePct)) · \(Fmt.termDescription(months: scenario.termMonths))")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(Fmt.moneyWhole(s.monthlyPayment, symbol: symbol))
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("per month")
                    .font(Theme.rounded(10))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(selected ? Theme.accent : Theme.hairline, lineWidth: selected ? 2 : 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(scenario.name)
        .accessibilityValue("\(scenario.loanType.label) loan, \(Fmt.moneyWhole(s.monthlyPayment, symbol: symbol)) per month.")
    }
}
