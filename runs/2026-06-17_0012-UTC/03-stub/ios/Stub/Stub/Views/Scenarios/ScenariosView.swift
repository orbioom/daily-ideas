import SwiftUI
import SwiftData

/// Saved scenarios list with CRUD, duplicate, swipe-delete, and load-into-calculator.
struct ScenariosView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppPreferences.self) private var prefs
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isPro") private var isPro = false

    /// Loads a scenario into the Calculator (handled by MainTabView).
    var loadIntoCalculator: (PayScenario) -> Void

    @Query(sort: \PayScenario.createdAt, order: .reverse) private var scenarios: [PayScenario]

    @State private var renameTarget: PayScenario?
    @State private var renameText = ""
    @State private var showPaywall = false
    @State private var exportText: String?

    private let freeScenarioLimit = 2

    var body: some View {
        NavigationStack {
            Group {
                if scenarios.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .background(StubTheme.appBackground(scheme).ignoresSafeArea())
            .navigationTitle("Scenarios")
            .toolbar {
                if !scenarios.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                exportCSV()
                            } label: {
                                Label(isPro ? "Export CSV" : "Export CSV (Pro)",
                                      systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .accessibilityLabel("More actions")
                    }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(item: Binding(get: { exportText.map { ExportPayload(text: $0) } },
                                 set: { exportText = $0?.text })) { payload in
                ExportSheet(text: payload.text)
            }
            .alert("Rename scenario", isPresented: Binding(
                get: { renameTarget != nil },
                set: { if !$0 { renameTarget = nil } })) {
                TextField("Name", text: $renameText)
                Button("Cancel", role: .cancel) { renameTarget = nil }
                Button("Save") { commitRename() }
            }
        }
    }

    // MARK: - List

    private var list: some View {
        List {
            Section {
                ForEach(scenarios) { scenario in
                    ScenarioRow(scenario: scenario, roundWhole: prefs.roundWhole)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Haptics.tap(enabled: prefs.hapticsEnabled)
                            loadIntoCalculator(scenario)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                delete(scenario)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                duplicate(scenario)
                            } label: {
                                Label("Duplicate", systemImage: "plus.square.on.square")
                            }
                            .tint(StubTheme.green)
                            Button {
                                renameTarget = scenario
                                renameText = scenario.name
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(StubTheme.state)
                        }
                        .listRowBackground(StubTheme.cardSurface(scheme))
                }
            } footer: {
                Text(isPro
                     ? "Tap a scenario to load it into the Calculator."
                     : "Free plan saves up to \(freeScenarioLimit) scenarios. Tap one to load it.")
                    .font(.caption)
            }
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Actions

    private func delete(_ scenario: PayScenario) {
        Haptics.tap(enabled: prefs.hapticsEnabled)
        modelContext.delete(scenario)
        try? modelContext.save()
    }

    private func duplicate(_ scenario: PayScenario) {
        if !isPro && scenarios.count >= freeScenarioLimit {
            showPaywall = true
            return
        }
        let copy = PayScenario(
            name: scenario.name + " (copy)",
            payType: scenario.payType,
            payFrequency: scenario.payFrequency,
            filingStatus: scenario.filingStatus,
            stateCode: scenario.stateCode,
            rate: scenario.rate,
            hoursPerWeek: scenario.hoursPerWeek,
            annualSalary: scenario.annualSalary,
            pretax401kPercent: scenario.pretax401kPercent,
            pretax401kDollar: scenario.pretax401kDollar,
            hsaAnnual: scenario.hsaAnnual,
            healthPremiumPerPay: scenario.healthPremiumPerPay,
            otherPretaxPerPay: scenario.otherPretaxPerPay,
            postTaxPerPay: scenario.postTaxPerPay,
            extraWithholdingPerPay: scenario.extraWithholdingPerPay
        )
        modelContext.insert(copy)
        try? modelContext.save()
        Haptics.success(enabled: prefs.hapticsEnabled)
    }

    private func commitRename() {
        guard let target = renameTarget else { return }
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            target.name = trimmed
            try? modelContext.save()
        }
        renameTarget = nil
    }

    private func exportCSV() {
        guard isPro else { showPaywall = true; return }
        exportText = CSVExport.string(for: scenarios, roundWhole: prefs.roundWhole)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "tray")
                .font(.system(size: 52))
                .foregroundStyle(StubTheme.green.opacity(0.7))
                .accessibilityHidden(true)
            Text("No saved scenarios")
                .font(.title3.weight(.semibold))
                .foregroundStyle(StubTheme.primaryText(scheme))
            Text("Build an estimate on the Calculator tab and tap “Save as scenario” to keep it here for comparing.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(StubTheme.secondaryText(scheme))
                .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

/// A single row in the scenarios list.
private struct ScenarioRow: View {
    @Environment(\.colorScheme) private var scheme
    let scenario: PayScenario
    let roundWhole: Bool

    var body: some View {
        let result = scenario.result
        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(scenario.name)
                    .font(.headline)
                    .foregroundStyle(StubTheme.primaryText(scheme))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    tag(scenario.payFrequency.shortLabel)
                    tag(scenario.filingStatus.shortLabel)
                    tag(scenario.stateCode)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Format.currency(result.netPerPaycheck, whole: roundWhole))
                    .font(StubTheme.figureFont(.subheadline, weight: .bold))
                    .foregroundStyle(StubTheme.green)
                Text("per paycheck")
                    .font(.caption2)
                    .foregroundStyle(StubTheme.secondaryText(scheme))
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(scenario.name), \(Format.currencySpoken(result.netPerPaycheck, whole: roundWhole)) per paycheck. Double tap to load.")
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(StubTheme.secondaryText(scheme))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Capsule().fill(StubTheme.subtleSurface(scheme)))
    }
}

/// Wrapper so the export string can drive a `.sheet(item:)`.
private struct ExportPayload: Identifiable {
    let id = UUID()
    let text: String
}
