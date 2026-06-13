import SwiftUI
import SwiftData

struct DebtEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("currencyCode") private var currencyCode = "USD"

    let debt: Debt?
    let nextIndex: Int

    @State private var name: String
    @State private var kind: DebtKind
    @State private var balance: String
    @State private var apr: String
    @State private var minimum: String
    @State private var resetStarting: Bool = false

    init(debt: Debt?, nextIndex: Int) {
        self.debt = debt
        self.nextIndex = nextIndex
        _name = State(initialValue: debt?.name ?? "")
        _kind = State(initialValue: debt?.kind ?? .creditCard)
        _balance = State(initialValue: debt.map { numString($0.balance) } ?? "")
        _apr = State(initialValue: debt.map { numString($0.apr) } ?? "")
        _minimum = State(initialValue: debt.map { numString($0.minimumPayment) } ?? "")
    }

    private var balanceValue: Double { Double(balance) ?? -1 }
    private var aprValue: Double { Double(apr) ?? -1 }
    private var minValue: Double { Double(minimum) ?? -1 }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        balanceValue >= 0 && balanceValue <= 100_000_000 &&
        aprValue >= 0 && aprValue <= 100 &&
        minValue >= 0 && minValue <= max(1, balanceValue) + 0.01
    }

    private var minTooLow: Bool {
        // A minimum below the monthly interest can never pay the debt off on its own.
        guard balanceValue > 0, aprValue > 0, minValue >= 0 else { return false }
        return minValue > 0 && minValue < balanceValue * aprValue / 1200.0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    Section("Debt") {
                        TextField("Name (e.g. Visa, Car loan)", text: $name)
                        Picker("Type", selection: $kind) {
                            ForEach(DebtKind.allCases) { k in
                                Label(k.label, systemImage: k.icon).tag(k)
                            }
                        }
                    }
                    Section("Numbers") {
                        labelledField("Balance owed", text: $balance, suffix: currencySymbol)
                        labelledField("Interest rate (APR)", text: $apr, suffix: "%")
                        labelledField("Minimum payment", text: $minimum, suffix: currencySymbol)
                    }
                    if minTooLow {
                        Section {
                            Label("That minimum is below the monthly interest, so this debt would grow if it isn’t your focus. Your plan’s extra payments will still clear it.",
                                  systemImage: "exclamationmark.triangle.fill")
                                .font(Theme.rounded(13, .medium))
                                .foregroundStyle(Theme.warn)
                        }
                    }
                    if debt != nil {
                        Section {
                            Toggle("Reset starting balance to this", isOn: $resetStarting)
                        } footer: {
                            Text("Turn on if you changed the balance and want progress measured from now.")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(debt == nil ? "Add debt" : "Edit debt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!isValid).bold()
                }
            }
        }
    }

    private var currencySymbol: String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = currencyCode
        return f.currencySymbol ?? "$"
    }

    private func labelledField(_ title: String, text: Binding<String>, suffix: String) -> some View {
        HStack {
            Text(title).foregroundStyle(Theme.ink)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
            Text(suffix).foregroundStyle(Theme.inkSoft)
        }
    }

    private func save() {
        guard isValid else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let debt {
            debt.name = trimmed
            debt.kind = kind
            if resetStarting || balanceValue > debt.startingBalance {
                debt.startingBalance = balanceValue
            }
            debt.balance = balanceValue
            debt.apr = aprValue
            debt.minimumPayment = minValue
        } else {
            let d = Debt(name: trimmed, kind: kind, balance: balanceValue,
                         apr: aprValue, minimumPayment: minValue, sortIndex: nextIndex)
            context.insert(d)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

private func numString(_ value: Double) -> String {
    if value == value.rounded() { return String(Int(value)) }
    return String(format: "%.2f", value)
}
