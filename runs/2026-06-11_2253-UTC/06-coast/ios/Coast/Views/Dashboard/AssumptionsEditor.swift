import SwiftUI
import SwiftData

/// Edit the plan inputs. Live-updates the FI number as you type.
struct AssumptionsEditor: View {
    @Bindable var profile: Profile
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    @State private var ageText = ""
    @State private var expensesText = ""
    @State private var investedText = ""
    @State private var contributionText = ""
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("About you") {
                    numberRow("Current age", text: $ageText, suffix: "yrs")
                    numberRow("Annual spending", text: $expensesText,
                              prefix: FIEngine.currencySymbol(profile.currencyCode))
                }
                Section("Your investments") {
                    numberRow("Currently invested", text: $investedText,
                              prefix: FIEngine.currencySymbol(profile.currencyCode))
                    numberRow("Added per year", text: $contributionText,
                              prefix: FIEngine.currencySymbol(profile.currencyCode))
                }
                Section {
                    sliderRow(title: "Expected real return",
                              value: $profile.realReturn, range: 0.01...0.10, step: 0.005,
                              format: { "\(String(format: "%.1f", $0 * 100))%" })
                    sliderRow(title: "Withdrawal rate",
                              value: $profile.withdrawalRate, range: 0.025...0.06, step: 0.0025,
                              format: { "\(String(format: "%.2f", $0 * 100))%" })
                } header: {
                    Text("Assumptions")
                } footer: {
                    Text("Real return is your portfolio's growth after inflation (4–5% is a common, conservative stock-market figure). The withdrawal rate is the share you can safely spend each year — 4% is the classic rule.")
                }

                Section {
                    HStack {
                        Text("Your FI number")
                            .font(.headline)
                        Spacer()
                        Text(FIEngine.money(previewFINumber, code: profile.currencyCode))
                            .font(Theme.display(20))
                            .foregroundStyle(Theme.teal)
                    }
                }

                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Assumptions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear { populate() }
        }
    }

    private var previewFINumber: Double {
        let expenses = parse(expensesText) ?? profile.annualExpenses
        return profile.withdrawalRate > 0 ? expenses / profile.withdrawalRate : 0
    }

    private func numberRow(_ label: String, text: Binding<String>,
                           prefix: String? = nil, suffix: String? = nil) -> some View {
        HStack {
            Text(label)
            Spacer()
            if let prefix { Text(prefix).foregroundStyle(.secondary) }
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 120)
                .accessibilityLabel(label)
            if let suffix { Text(suffix).foregroundStyle(.secondary) }
        }
    }

    private func sliderRow(title: String, value: Binding<Double>,
                           range: ClosedRange<Double>, step: Double,
                           format: @escaping (Double) -> String) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                Spacer()
                Text(format(value.wrappedValue))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: step) { Text(title) }
                .tint(Theme.teal)
        }
    }

    private func populate() {
        ageText = trimNumber(profile.currentAge)
        expensesText = trimNumber(profile.annualExpenses)
        investedText = trimNumber(profile.currentInvested)
        contributionText = trimNumber(profile.annualContribution)
    }

    private func trimNumber(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(value)
    }

    private func parse(_ text: String) -> Double? {
        let cleaned = text.replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        if cleaned.isEmpty { return 0 }
        guard let v = Double(cleaned), v >= 0, v < 1_000_000_000 else { return nil }
        return v
    }

    private func save() {
        guard let age = parse(ageText), age >= 10, age <= 100 else {
            validationMessage = "Enter an age between 10 and 100."
            return
        }
        guard let expenses = parse(expensesText), expenses > 0 else {
            validationMessage = "Annual spending must be above zero."
            return
        }
        guard let invested = parse(investedText) else {
            validationMessage = "Invested amount must be a valid number."
            return
        }
        guard let contribution = parse(contributionText) else {
            validationMessage = "Yearly contribution must be a valid number."
            return
        }
        profile.currentAge = age
        profile.annualExpenses = expenses
        profile.currentInvested = invested
        profile.annualContribution = contribution
        Haptics.success()
        dismiss()
    }
}
