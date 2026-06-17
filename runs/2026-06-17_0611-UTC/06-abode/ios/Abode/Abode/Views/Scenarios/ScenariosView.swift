import SwiftUI
import SwiftData

/// Saved scenarios: a list with rename/delete, plus a side-by-side Pro comparison.
struct ScenariosView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppSettings.self) private var settings
    @Environment(ProStore.self) private var pro
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MortgageScenario.createdAt, order: .reverse) private var scenarios: [MortgageScenario]

    @State private var selectedIDs: Set<UUID> = []
    @State private var renaming: MortgageScenario?
    @State private var renameText = ""
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                AbodeTheme.appBackground(scheme).ignoresSafeArea()
                if scenarios.isEmpty {
                    EmptyStateView(
                        icon: "square.stack.3d.up",
                        title: "No saved scenarios",
                        message: "Save a calculation from the Calculator tab to keep it here and compare it with others."
                    )
                } else {
                    list
                }
            }
            .navigationTitle("Scenarios")
            .toolbar {
                if !scenarios.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            compareDestination
                        } label: {
                            Image(systemName: "rectangle.split.3x1")
                        }
                        .disabled(selectedIDs.count < 2)
                        .accessibilityLabel("Compare selected")
                    }
                }
            }
            .sheet(item: $renaming) { scenario in renameSheet(scenario) }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Tap to select two or more, then compare.")
                    .font(.caption)
                    .foregroundStyle(AbodeTheme.secondaryText(scheme))
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVStack(spacing: 10) {
                    ForEach(scenarios) { scenario in
                        ScenarioCard(
                            scenario: scenario,
                            selected: selectedIDs.contains(scenario.id),
                            onTap: { toggle(scenario) },
                            onRename: { startRename(scenario) },
                            onDelete: { delete(scenario) }
                        )
                    }
                }
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private var compareDestination: some View {
        if pro.isPro {
            let chosen = scenarios.filter { selectedIDs.contains($0.id) }
            CompareView(scenarios: chosen)
        } else {
            ScrollView {
                AbodeCard {
                    ProLockView(
                        feature: "Side-by-side compare",
                        detail: "Compare payment, total interest, and payoff across your scenarios with a clear chart.",
                        showPaywall: $showPaywall
                    )
                }
                .padding(16)
            }
            .abodeScreenBackground(scheme)
            .navigationTitle("Compare")
        }
    }

    // MARK: Actions

    private func toggle(_ scenario: MortgageScenario) {
        Haptics.tap(settings.hapticsEnabled)
        if selectedIDs.contains(scenario.id) { selectedIDs.remove(scenario.id) }
        else { selectedIDs.insert(scenario.id) }
    }

    private func startRename(_ scenario: MortgageScenario) {
        renameText = scenario.name
        renaming = scenario
    }

    private func delete(_ scenario: MortgageScenario) {
        selectedIDs.remove(scenario.id)
        modelContext.delete(scenario)
        try? modelContext.save()
        Haptics.warning(settings.hapticsEnabled)
    }

    private func renameSheet(_ scenario: MortgageScenario) -> some View {
        NavigationStack {
            ZStack {
                AbodeTheme.appBackground(scheme).ignoresSafeArea()
                VStack(spacing: 18) {
                    AbodeCard {
                        VStack(alignment: .leading, spacing: 10) {
                            AbodeSectionHeader(title: "Rename scenario")
                            TextField("Name", text: $renameText)
                                .textFieldStyle(.roundedBorder)
                                .accessibilityLabel("Scenario name")
                        }
                    }
                    Button("Save") {
                        let name = renameText.trimmingCharacters(in: .whitespaces)
                        if !name.isEmpty { scenario.name = name; try? modelContext.save() }
                        renaming = nil
                    }
                    .buttonStyle(AbodePrimaryButtonStyle())
                    .disabled(renameText.trimmingCharacters(in: .whitespaces).isEmpty)
                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("Rename")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { renaming = nil }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

/// A single scenario summary card with select / rename / delete.
struct ScenarioCard: View {
    @Environment(\.colorScheme) private var scheme
    let scenario: MortgageScenario
    let selected: Bool
    let onTap: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        let input = scenario.asLoanInput
        let breakdown = MortgageEngine.breakdown(input)
        Button(action: onTap) {
            AbodeCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selected ? AbodeTheme.accent : AbodeTheme.secondaryText(scheme))
                            .accessibilityHidden(true)
                        Text(scenario.name)
                            .font(.headline)
                            .foregroundStyle(AbodeTheme.primaryText(scheme))
                        Spacer()
                        Menu {
                            Button("Rename", systemImage: "pencil", action: onRename)
                            Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundStyle(AbodeTheme.secondaryText(scheme))
                        }
                        .accessibilityLabel("More actions")
                    }
                    HStack(spacing: 16) {
                        miniStat("Monthly", Format.money(breakdown.total, forceWhole: true))
                        miniStat("Rate", Format.percentValue(input.annualRatePct, fractionDigits: 2))
                        miniStat("Term", "\(input.termYears) yr")
                    }
                    Text("\(Format.money(input.homePrice, forceWhole: true)) • \(Format.percentFraction(input.ltv, fractionDigits: 0)) LTV")
                        .font(.caption)
                        .foregroundStyle(AbodeTheme.secondaryText(scheme))
                }
            }
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(selected ? AbodeTheme.accent : Color.clear, lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(scenario.name)
        .accessibilityValue("Monthly \(Format.money(breakdown.total, forceWhole: true)), \(selected ? "selected" : "not selected")")
        .accessibilityHint("Double-tap to toggle selection for comparison")
    }

    private func miniStat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(AbodeTheme.secondaryText(scheme))
            Text(value)
                .font(AbodeTheme.figure(.subheadline, weight: .semibold))
                .foregroundStyle(AbodeTheme.primaryText(scheme))
        }
    }
}
