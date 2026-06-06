import SwiftUI
import SwiftData

struct DebtEditView: View {
    @Bindable var debt: Debt
    var isNew: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var balanceText = ""
    @State private var aprText = ""
    @State private var minText = ""

    private var trimmedName: String { debt.name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool {
        !trimmedName.isEmpty && (Double(balanceText.replacingOccurrences(of: ",", with: ".")) ?? 0) >= 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Debt") {
                    TextField("Name", text: $debt.name)
                    Picker("Type", selection: Binding(get: { debt.kind }, set: { debt.kind = $0 })) {
                        ForEach(DebtKind.allCases) { Text($0.label).tag($0) }
                    }
                }
                Section("Numbers") {
                    money("Balance", $balanceText)
                    HStack {
                        Text("APR %"); Spacer()
                        TextField("0", text: $aprText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(width: 90).font(Brand.mono(16))
                    }
                    money("Minimum payment", $minText)
                }
                Section {
                    Toggle("Include in payoff plan", isOn: $debt.includeInPlan)
                } footer: {
                    if let bal = Double(balanceText.replacingOccurrences(of: ",", with: ".")),
                       let apr = Double(aprText.replacingOccurrences(of: ",", with: ".")),
                       let m = Double(minText.replacingOccurrences(of: ",", with: ".")),
                       bal > 0, apr > 0 {
                        let interest = bal * apr / 100 / 12
                        if m <= interest {
                            Text("Warning: the minimum payment is less than the first month's interest (\(String(format: "%.2f", interest))). This balance won't go down on minimums alone.")
                                .foregroundStyle(Brand.danger)
                        } else {
                            Text("First month's interest: about \(String(format: "%.2f", interest)).")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(isNew ? "New Debt" : "Edit Debt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { cancel() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave).fontWeight(.semibold)
                }
            }
            .onAppear {
                if debt.balance > 0 { balanceText = trim(debt.balance) }
                if debt.apr > 0 { aprText = trim(debt.apr) }
                if debt.minPayment > 0 { minText = trim(debt.minPayment) }
            }
        }
    }

    private func money(_ label: String, _ binding: Binding<String>) -> some View {
        HStack {
            Text(label); Spacer()
            TextField("0", text: binding).keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing).frame(width: 110).font(Brand.mono(16))
        }
    }
    private func trim(_ d: Double) -> String { d == d.rounded() ? String(Int(d)) : String(d) }
    private func parse(_ s: String) -> Double { max(0, Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0) }

    private func save() {
        debt.name = trimmedName
        debt.balance = parse(balanceText)
        debt.apr = parse(aprText)
        debt.minPayment = parse(minText)
        try? context.save(); Haptics.success(); dismiss()
    }
    private func cancel() { if isNew { context.delete(debt) }; dismiss() }
}
