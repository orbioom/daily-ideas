import SwiftUI
import SwiftData

struct ScenarioEditorView: View {
    let scenario: Scenario?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allScenarios: [Scenario]
    @AppStorage("currencySymbol") private var currencySymbol = "$"

    @State private var name = "My plan"
    @State private var currentAge = 30.0
    @State private var targetAge = 60.0
    @State private var invested = "50000"
    @State private var monthly = "1000"
    @State private var spending = "40000"
    @State private var returnPct = 7.0
    @State private var inflationPct = 2.5
    @State private var swrPct = 4.0
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Scenario") {
                    TextField("Name", text: $name)
                }

                Section("You") {
                    Stepper("Current age: \(Int(currentAge))", value: $currentAge, in: 16...90)
                    Stepper("Want the option to stop by: \(Int(targetAge))", value: $targetAge, in: 25...90)
                }

                Section("Money — today's values") {
                    LabeledContent("Invested now") {
                        TextField("0", text: $invested)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Amount invested now")
                    }
                    LabeledContent("Contribution / month") {
                        TextField("0", text: $monthly)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Monthly contribution")
                    }
                    LabeledContent("Spending / year in retirement") {
                        TextField("0", text: $spending)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Annual retirement spending")
                    }
                }

                Section {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Expected return")
                            Spacer()
                            Text(String(format: "%.1f%%", returnPct)).foregroundStyle(Theme.textSecondary)
                        }
                        Slider(value: $returnPct, in: 1...12, step: 0.5)
                            .accessibilityLabel("Expected annual return")
                            .accessibilityValue(String(format: "%.1f percent", returnPct))
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Inflation")
                            Spacer()
                            Text(String(format: "%.1f%%", inflationPct)).foregroundStyle(Theme.textSecondary)
                        }
                        Slider(value: $inflationPct, in: 0...8, step: 0.5)
                            .accessibilityLabel("Expected inflation")
                            .accessibilityValue(String(format: "%.1f percent", inflationPct))
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Withdrawal rate")
                            Spacer()
                            Text(String(format: "%.1f%%", swrPct)).foregroundStyle(Theme.textSecondary)
                        }
                        Slider(value: $swrPct, in: 2...6, step: 0.25)
                            .accessibilityLabel("Safe withdrawal rate")
                            .accessibilityValue(String(format: "%.2f percent", swrPct))
                    }
                } header: {
                    Text("Assumptions")
                } footer: {
                    Text("7% nominal / 2.5% inflation roughly tracks long-run global equities. The classic \u{201C}4% rule\u{201D} comes from the Trinity study; 3–3.5% is more conservative for early retirees.")
                }

                if let preview = previewResult {
                    Section("Preview") {
                        LabeledContent("FIRE number",
                                       value: FireEngine.money(preview.fireNumber, symbol: currencySymbol, compact: true))
                        LabeledContent("Projected FI age",
                                       value: preview.fiAge.map { FireEngine.age($0) } ?? "not reached by 80")
                        LabeledContent("Coast FIRE number",
                                       value: FireEngine.money(preview.coastNumber, symbol: currencySymbol, compact: true))
                    }
                }
            }
            .navigationTitle(scenario == nil ? "New scenario" : "Edit scenario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .alert("Check your inputs", isPresented: Binding(
                get: { validationMessage != nil },
                set: { if !$0 { validationMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage ?? "")
            }
            .onAppear(perform: load)
        }
    }

    private var previewResult: FireEngine.Result? {
        guard let inv = Double(invested), let mon = Double(monthly),
              let spend = Double(spending), spend > 0 else { return nil }
        let temp = Scenario(name: name, currentAge: Int(currentAge),
                            targetRetirementAge: Int(targetAge),
                            currentInvested: max(0, inv), monthlyContribution: max(0, mon),
                            expectedReturnPct: returnPct, inflationPct: inflationPct,
                            annualSpending: spend, swrPct: swrPct)
        return FireEngine.evaluate(temp)
    }

    private func load() {
        guard let scenario else { return }
        name = scenario.name
        currentAge = Double(scenario.currentAge)
        targetAge = Double(scenario.targetRetirementAge)
        invested = String(format: "%.0f", scenario.currentInvested)
        monthly = String(format: "%.0f", scenario.monthlyContribution)
        spending = String(format: "%.0f", scenario.annualSpending)
        returnPct = scenario.expectedReturnPct
        inflationPct = scenario.inflationPct
        swrPct = scenario.swrPct
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            validationMessage = "Give the scenario a name."
            return
        }
        guard let inv = Double(invested), inv >= 0 else {
            validationMessage = "\u{201C}Invested now\u{201D} must be a number (0 is fine)."
            return
        }
        guard let mon = Double(monthly), mon >= 0 else {
            validationMessage = "\u{201C}Contribution / month\u{201D} must be a number (0 is fine)."
            return
        }
        guard let spend = Double(spending), spend > 0 else {
            validationMessage = "\u{201C}Spending / year\u{201D} must be a positive number — it defines your FIRE number."
            return
        }
        guard targetAge > currentAge else {
            validationMessage = "The target age must be after your current age."
            return
        }

        if let scenario {
            scenario.name = trimmedName
            scenario.currentAge = Int(currentAge)
            scenario.targetRetirementAge = Int(targetAge)
            scenario.currentInvested = inv
            scenario.monthlyContribution = mon
            scenario.annualSpending = spend
            scenario.expectedReturnPct = returnPct
            scenario.inflationPct = inflationPct
            scenario.swrPct = swrPct
        } else {
            let new = Scenario(name: trimmedName, currentAge: Int(currentAge),
                               targetRetirementAge: Int(targetAge), currentInvested: inv,
                               monthlyContribution: mon, expectedReturnPct: returnPct,
                               inflationPct: inflationPct, annualSpending: spend,
                               swrPct: swrPct, isPrimary: allScenarios.isEmpty)
            context.insert(new)
        }
        Haptics.success()
        dismiss()
    }
}
