import SwiftUI
import SwiftData

/// List of saved scenarios with side-by-side comparison. Compare & unlimited
/// scenarios are Pro; free is limited to one saved scenario.
struct ScenariosView: View {
    @Environment(\.modelContext) private var context
    @Environment(StoreManager.self) private var store

    @Query(sort: \TaxScenario.createdAt, order: .reverse) private var scenarios: [TaxScenario]

    @State private var showPaywall = false
    @State private var compareA: TaxScenario?
    @State private var compareB: TaxScenario?
    @State private var showCompare = false
    @State private var renaming: TaxScenario?

    var body: some View {
        NavigationStack {
            Group {
                if scenarios.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .background(Theme.background)
            .navigationTitle("Scenarios")
            .toolbar {
                if !scenarios.isEmpty && store.isPro {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            startCompare()
                        } label: {
                            Label("Compare", systemImage: "arrow.left.arrow.right")
                        }
                        .disabled(scenarios.count < 2)
                    }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showCompare) {
                if let a = compareA, let b = compareB {
                    CompareView(a: a, b: b)
                }
            }
            .sheet(item: $renaming) { scenario in
                RenameScenarioSheet(scenario: scenario)
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "square.on.square",
            title: "No saved scenarios",
            message: "Save snapshots of your numbers from the Estimate tab, then compare them here to see which plan owes less.",
            actionTitle: nil,
            action: nil
        )
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.m) {
                if !store.isPro {
                    freeBanner
                }
                ForEach(scenarios) { scenario in
                    scenarioCard(scenario)
                }
            }
            .padding(Theme.Spacing.m)
        }
    }

    private var freeBanner: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: "sparkles")
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Free plan: 1 saved scenario")
                    .font(.subheadline.weight(.semibold))
                Text("Unlock Pro for unlimited scenarios and side-by-side compare.")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            Button("Unlock") { showPaywall = true }
                .font(.subheadline.weight(.semibold))
        }
        .card()
    }

    private func scenarioCard(_ scenario: TaxScenario) -> some View {
        let est = scenario.estimate
        return VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack {
                Text(scenario.name)
                    .font(.headline)
                Spacer()
                Text("\(scenario.year) · \(scenario.filingStatus.shortLabel)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
            }
            HStack(alignment: .firstTextBaseline) {
                Text(Format.money(est.totalTax))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.accent)
                Text("estimated tax")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            HStack(spacing: Theme.Spacing.m) {
                miniStat("SE income", Format.money(Decimal(scenario.selfEmploymentIncome)))
                miniStat("Effective", Format.percentFromFraction(est.effectiveRate))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(scenario.name), \(scenario.year), \(scenario.filingStatus.shortLabel)")
        .accessibilityValue("Estimated tax \(Format.money(est.totalTax))")
        .contextMenu {
            Button {
                renaming = scenario
            } label: { Label("Rename", systemImage: "pencil") }
            Button(role: .destructive) {
                delete(scenario)
            } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func miniStat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func startCompare() {
        guard scenarios.count >= 2 else { return }
        compareA = scenarios[0]
        compareB = scenarios[1]
        showCompare = true
        Haptics.tap()
    }

    private func delete(_ scenario: TaxScenario) {
        context.delete(scenario)
        try? context.save()
        Haptics.tap()
    }
}

// MARK: - Compare view

struct CompareView: View {
    @Environment(\.dismiss) private var dismiss
    let a: TaxScenario
    let b: TaxScenario

    private var estA: TaxEstimate { a.estimate }
    private var estB: TaxEstimate { b.estimate }

    private var delta: Decimal { estA.totalTax - estB.totalTax }
    private var winnerName: String {
        if estA.totalTax == estB.totalTax { return "It's a tie" }
        return estA.totalTax < estB.totalTax ? a.name : b.name
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.l) {
                    verdict
                    columns
                    rows
                }
                .padding(Theme.Spacing.m)
            }
            .background(Theme.background)
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var verdict: some View {
        VStack(spacing: Theme.Spacing.s) {
            Text(estA.totalTax == estB.totalTax ? "Both owe the same" : "\(winnerName) owes less")
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)
            if delta != 0 {
                Text("Difference of \(Format.money(abs(delta)))")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.l)
        .background(Theme.accent.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var columns: some View {
        HStack(spacing: Theme.Spacing.m) {
            columnHeader(a.name, est: estA, isWinner: estA.totalTax <= estB.totalTax)
            columnHeader(b.name, est: estB, isWinner: estB.totalTax <= estA.totalTax)
        }
    }

    private func columnHeader(_ name: String, est: TaxEstimate, isWinner: Bool) -> some View {
        VStack(spacing: Theme.Spacing.s) {
            Text(name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            Text(Format.money(est.totalTax))
                .font(.title2.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(isWinner ? Theme.accent : Theme.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.m)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(isWinner ? Theme.accent : .clear, lineWidth: 2)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityValue("Total tax \(Format.money(est.totalTax))\(isWinner ? ", lower" : "")")
    }

    private var rows: some View {
        VStack(spacing: 0) {
            compareRow("SE tax", estA.seTax, estB.seTax)
            Divider()
            compareRow("Federal income tax", estA.federalIncomeTax, estB.federalIncomeTax)
            Divider()
            compareRow("State tax", estA.stateTax, estB.stateTax)
            Divider()
            compareRow("Taxable income", estA.taxableIncome, estB.taxableIncome)
            Divider()
            comparePercentRow("Effective rate", estA.effectiveRate, estB.effectiveRate)
        }
        .card()
    }

    private func compareRow(_ label: String, _ va: Decimal, _ vb: Decimal) -> some View {
        HStack {
            Text(Format.money(va)).monospacedDigit().frame(maxWidth: .infinity, alignment: .leading)
            Text(label).font(.caption).foregroundStyle(Theme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(Format.money(vb)).monospacedDigit().frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue("\(a.name) \(Format.money(va)), \(b.name) \(Format.money(vb))")
    }

    private func comparePercentRow(_ label: String, _ va: Decimal, _ vb: Decimal) -> some View {
        HStack {
            Text(Format.percentFromFraction(va)).monospacedDigit().frame(maxWidth: .infinity, alignment: .leading)
            Text(label).font(.caption).foregroundStyle(Theme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(Format.percentFromFraction(vb)).monospacedDigit().frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue("\(a.name) \(Format.percentFromFraction(va)), \(b.name) \(Format.percentFromFraction(vb))")
    }
}

// MARK: - Rename sheet

struct RenameScenarioSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var scenario: TaxScenario

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Scenario name", text: $scenario.name)
                }
                Section("Notes") {
                    TextField("Optional notes", text: $scenario.notes, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .navigationTitle("Rename")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
