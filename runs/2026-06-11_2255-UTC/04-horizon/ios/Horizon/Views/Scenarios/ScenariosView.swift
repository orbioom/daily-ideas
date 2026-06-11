import SwiftUI
import SwiftData

struct ScenariosView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Scenario.createdAt) private var scenarios: [Scenario]
    @AppStorage("currencySymbol") private var currencySymbol = "$"
    @State private var editing: Scenario?
    @State private var creating = false

    var body: some View {
        NavigationStack {
            Group {
                if scenarios.isEmpty {
                    EmptyStateView(
                        icon: "slider.horizontal.3",
                        title: "No scenarios",
                        message: "Scenarios are alternate futures — \u{201C}what if I save \(currencySymbol)500 more?\u{201D}, \u{201C}what if I retire at 55?\u{201D}. Create one to start.",
                        actionTitle: "New scenario"
                    ) { creating = true }
                } else {
                    List {
                        ForEach(scenarios) { scenario in
                            row(scenario)
                                .contentShape(Rectangle())
                                .onTapGesture { editing = scenario }
                                .listRowBackground(Theme.bgElevated)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        delete(scenario)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button {
                                        duplicate(scenario)
                                    } label: {
                                        Label("Duplicate", systemImage: "plus.square.on.square")
                                    }
                                    .tint(.indigo)
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        makePrimary(scenario)
                                    } label: {
                                        Label("Primary", systemImage: "star")
                                    }
                                    .tint(Theme.gold)
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.bgPrimary)
            .navigationTitle("Scenarios")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { creating = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New scenario")
                }
            }
            .sheet(item: $editing) { scenario in
                ScenarioEditorView(scenario: scenario)
            }
            .sheet(isPresented: $creating) {
                ScenarioEditorView(scenario: nil)
            }
        }
    }

    private func row(_ scenario: Scenario) -> some View {
        let result = FireEngine.evaluate(scenario)
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if scenario.isPrimary {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(Theme.gold)
                            .accessibilityLabel("Primary scenario")
                    }
                    Text(scenario.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                }
                Text("\(FireEngine.money(scenario.currentInvested, symbol: currencySymbol, compact: true)) invested · \(FireEngine.money(scenario.monthlyContribution, symbol: currencySymbol, compact: true))/mo · retire by \(scenario.targetRetirementAge)")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(result.fiAge.map { "FI at \(FireEngine.age($0))" } ?? "FI not reached")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(result.fiAge == nil ? Theme.textSecondary : Theme.accent)
                Text("\(Int((result.progress * 100).rounded()))% there")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func makePrimary(_ scenario: Scenario) {
        for s in scenarios { s.isPrimary = false }
        scenario.isPrimary = true
        Haptics.success()
    }

    private func duplicate(_ s: Scenario) {
        let copy = Scenario(name: s.name + " copy", currentAge: s.currentAge,
                            targetRetirementAge: s.targetRetirementAge,
                            currentInvested: s.currentInvested,
                            monthlyContribution: s.monthlyContribution,
                            expectedReturnPct: s.expectedReturnPct,
                            inflationPct: s.inflationPct,
                            annualSpending: s.annualSpending, swrPct: s.swrPct)
        context.insert(copy)
        Haptics.tap()
    }

    private func delete(_ scenario: Scenario) {
        let wasPrimary = scenario.isPrimary
        context.delete(scenario)
        if wasPrimary, let next = scenarios.first(where: { $0.persistentModelID != scenario.persistentModelID }) {
            next.isPrimary = true
        }
    }
}
